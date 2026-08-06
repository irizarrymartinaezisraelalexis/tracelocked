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

    async def run_all(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        matches: list[ConnectorMatch] = []

        for connector in self.connectors:
            if not connector.enabled:
                continue

            try:
                connector_matches = await connector.search(profile)
                matches.extend(connector_matches)
            except Exception as error:
                print(
                    f"Connector {connector.name} failed: {error}"
                )

        return matches

    def enabled_connector_count(self) -> int:
        return sum(
            1
            for connector in self.connectors
            if connector.enabled
        )