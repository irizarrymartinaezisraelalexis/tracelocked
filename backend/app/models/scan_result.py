from typing import Literal

from pydantic import BaseModel


class ScanResultStatusUpdate(BaseModel):
    status: Literal[
        "possible_match",
        "confirmed_match",
        "removal_requested",
        "removed",
        "failed",
    ]