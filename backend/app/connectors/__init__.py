import os

from app.connectors.demo import DemoConnector
from app.connectors.google import GoogleConnector
from app.connectors.manager import ConnectorManager
from app.connectors.truepeoplesearch import TruePeopleSearchConnector


def env_flag(
    name: str,
    default: bool = False,
) -> bool:
    value = os.getenv(name)

    if value is None:
        return default

    return value.strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }


demo_connector = DemoConnector()
demo_connector.enabled = env_flag(
    "TRACELOCKED_DEMO_MODE",
    default=False,
)

google_connector = GoogleConnector()
true_people_search_connector = TruePeopleSearchConnector()

connector_manager = ConnectorManager(
    connectors=[
        demo_connector,
        google_connector,
        true_people_search_connector,
    ]
)