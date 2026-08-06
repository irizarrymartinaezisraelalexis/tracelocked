from app.connectors.demo import DemoConnector
from app.connectors.google import GoogleConnector
from app.connectors.manager import ConnectorManager
from app.connectors.truepeoplesearch import TruePeopleSearchConnector

connector_manager = ConnectorManager(
    connectors=[
        DemoConnector(),
        GoogleConnector(),
        TruePeopleSearchConnector(),
    ]
)