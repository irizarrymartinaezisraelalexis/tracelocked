from typing import Any

from app.connectors.base import BaseConnector, ConnectorMatch


class TruePeopleSearchConnector(BaseConnector):
    name = "TruePeopleSearch"
    enabled = False

    async def search(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        """
        TruePeopleSearch connector placeholder.

        Automated access is disabled until an approved and compliant
        integration method is selected.
        """
        return []