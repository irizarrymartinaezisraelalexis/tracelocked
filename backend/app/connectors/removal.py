from dataclasses import dataclass
from enum import Enum


class RemovalRequirement(str, Enum):
    NONE = "none"
    EMAIL_CONFIRMATION = "email_confirmation"
    CAPTCHA = "captcha"
    ACCOUNT_LOGIN = "account_login"
    IDENTITY_VERIFICATION = "identity_verification"
    MANUAL_FORM = "manual_form"
    UNKNOWN = "unknown"


class RemovalStatus(str, Enum):
    NOT_STARTED = "not_started"
    READY = "ready"
    ACTION_REQUIRED = "action_required"
    SUBMITTED = "submitted"
    WAITING = "waiting"
    REMOVED = "removed"
    FAILED = "failed"
    REAPPEARED = "reappeared"


@dataclass(frozen=True)
class RemovalCapability:
    source_key: str
    automated: bool
    supports_direct_submission: bool
    requires_confirmation: bool
    requirements: tuple[RemovalRequirement, ...]
    opt_out_url: str | None = None
    notes: str | None = None


REMOVAL_CAPABILITIES: tuple[RemovalCapability, ...] = (
    RemovalCapability(
        source_key="truecaller",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="beenverified",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="spokeo",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.CAPTCHA,
        ),
    ),
    RemovalCapability(
        source_key="peoplefinders",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="intelius",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="usphonebook",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="whitepages",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="truthfinder",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="instant_checkmate",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="mylife",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="fastpeoplesearch",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.EMAIL_CONFIRMATION,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="radaris",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="nuwber",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="peekyou",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="thatsthem",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="clustrmaps",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="familytreenow",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="zillow",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="redfin",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
    RemovalCapability(
        source_key="facebook",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
        ),
    ),
    RemovalCapability(
        source_key="instagram",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
        ),
    ),
    RemovalCapability(
        source_key="linkedin",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
        ),
    ),
    RemovalCapability(
        source_key="google_maps",
        automated=False,
        supports_direct_submission=False,
        requires_confirmation=True,
        requirements=(
            RemovalRequirement.ACCOUNT_LOGIN,
            RemovalRequirement.MANUAL_FORM,
        ),
    ),
)


def get_removal_capability(
    source_key: str,
) -> RemovalCapability | None:
    for capability in REMOVAL_CAPABILITIES:
        if capability.source_key == source_key:
            return capability

    return None


def list_removal_capabilities() -> list[RemovalCapability]:
    return list(REMOVAL_CAPABILITIES)