from app.routes._crud import build_crud_router
from app.schemas.domain import MCPAgentRun

router = build_crud_router(MCPAgentRun, "mcp-agent-runs")
