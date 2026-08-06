from typing import Any

from app.connectors.base import BaseConnector, ConnectorMatch


class DemoConnector(BaseConnector):
    name = "Demo People Search"
    enabled = True

    async def search(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        current_address = profile["current_address"]

        return [
            ConnectorMatch(
                source_name=self.name,
                source_url="https://example.com/demo-profile",
                matched_name=(
                    f"{profile['first_name']} "
                    f"{profile['last_name']}"
                ),
                matched_phone=(
                    profile["phone_numbers"][0]
                    if profile.get("phone_numbers")
                    else None
                ),
                matched_email=(
                    profile["email_addresses"][0]
                    if profile.get("email_addresses")
                    else None
                ),
                matched_address=(
                    f"{current_address['street']}, "
                    f"{current_address['city']}, "
                    f"{current_address['state']} "
                    f"{current_address['postal_code']}"
                ),
                confidence_score=95,
                status="possible_match",
            )
        ]