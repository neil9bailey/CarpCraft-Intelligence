from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated

import jwt
from fastapi import Header, HTTPException, Request, status
from jwt import PyJWKClient
from jwt.exceptions import InvalidTokenError

from app.core.config import get_settings


@dataclass(frozen=True, slots=True)
class Principal:
    user_id: str
    auth_mode: str
    tenant_id: str | None = None
    email: str | None = None
    roles: tuple[str, ...] = ()
    scopes: tuple[str, ...] = ()


def _is_production() -> bool:
    return get_settings().app_env.lower() in {"production", "prod"}


def _entra_issuer() -> str:
    settings = get_settings()
    return settings.entra_issuer or f"https://login.microsoftonline.com/{settings.entra_tenant_id}/v2.0"


def _entra_jwks_uri() -> str:
    settings = get_settings()
    return settings.entra_jwks_uri or f"https://login.microsoftonline.com/{settings.entra_tenant_id}/discovery/v2.0/keys"


def _entra_audiences() -> list[str]:
    settings = get_settings()
    raw = settings.entra_audiences or settings.entra_audience or ""
    return [value.strip() for value in raw.split(",") if value.strip()]


def _bearer_token(authorization_header: str | None) -> str | None:
    if not authorization_header:
        return None
    prefix = "Bearer "
    if not authorization_header.lower().startswith(prefix.lower()):
        return None
    return authorization_header[len(prefix) :].strip()


def _validate_entra_token(token: str) -> Principal:
    settings = get_settings()
    audiences = _entra_audiences()
    if not audiences:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ENTRA_AUDIENCE or ENTRA_AUDIENCES must be configured when AUTH_MODE=entra.",
        )

    try:
        signing_key = PyJWKClient(_entra_jwks_uri()).get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=audiences,
            issuer=_entra_issuer(),
            leeway=120,
        )
    except InvalidTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Invalid Microsoft Entra token: {exc}") from exc

    token_tenant_id = payload.get("tid")
    if token_tenant_id != settings.entra_tenant_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token tenant does not match DIIAC tenant.")

    user_id = payload.get("oid") or payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token is missing a stable user identifier.")

    scopes = tuple(str(payload.get("scp", "")).split()) if payload.get("scp") else ()
    roles = tuple(str(role) for role in payload.get("roles", []) if role)
    return Principal(
        user_id=str(user_id),
        auth_mode="entra",
        tenant_id=str(token_tenant_id),
        email=payload.get("preferred_username") or payload.get("upn"),
        roles=roles,
        scopes=scopes,
    )


def get_current_principal(
    request: Request,
    user_id_header: Annotated[str | None, Header(alias="X-CarpCraft-User-Id")] = None,
) -> Principal:
    settings = get_settings()
    if _is_production() and not settings.auth_required:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Production startup is misconfigured: AUTH_REQUIRED=true is mandatory.",
        )

    if settings.auth_mode.lower() == "entra" or settings.auth_required:
        token = _bearer_token(request.headers.get("Authorization"))
        if not token:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="A Microsoft Entra bearer token is required.")
        return _validate_entra_token(token)

    user_id = user_id_header or settings.local_dev_user_id
    return Principal(user_id=user_id, auth_mode="local-header")
