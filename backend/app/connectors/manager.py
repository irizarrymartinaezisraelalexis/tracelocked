import asyncio
from typing import Any

from app.connectors.base import BaseConnector, ConnectorMatch


class ConnectorManager:
    def __init__(
        self,
        connectors: list[BaseConnector] | None = None,
    ) -> None:
        self.connectors = connectors or []

    def register(
        self,
        connector: BaseConnector,
    ) -> None:
        self.connectors.append(connector)

    async def _run_connector(
        self,
        connector: BaseConnector,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        try:
            return await connector.search(profile)
        except Exception as error:
            print(
                f"Connector {connector.name} failed: {error}"
            )
            return []

    async def run_all(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        enabled_connectors = [
            connector
            for connector in self.connectors
            if connector.enabled
        ]

        if not enabled_connectors:
            return []

        connector_results = await asyncio.gather(
            *(
                self._run_connector(
                    connector,
                    profile,
                )
                for connector in enabled_connectors
            )
        )

        matches: list[ConnectorMatch] = []

        for result_group in connector_results:
            matches.extend(result_group)

        return matches

    def enabled_connector_count(self) -> int:
        return sum(
            1
            for connector in self.connectors
            if connector.enabled
        )