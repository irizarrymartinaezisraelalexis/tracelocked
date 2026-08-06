from typing import Any

from app.connectors.base import BaseConnector, ConnectorMatch


class GoogleConnector(BaseConnector):
    name = "Google Search"
    enabled = False

    async def search(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        """
        Google connector placeholder.

        Direct automated scraping is intentionally disabled.
        A supported search API can be integrated here later.
        """
        return []