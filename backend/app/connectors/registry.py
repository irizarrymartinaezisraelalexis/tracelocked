from dataclasses import dataclass
from enum import Enum


class SourceCategory(str, Enum):
    PEOPLE_SEARCH = "people_search"
    PHONE_LOOKUP = "phone_lookup"
    ADDRESS_LOOKUP = "address_lookup"
    PROPERTY_RECORDS = "property_records"
    SOCIAL = "social"
    BUSINESS_DIRECTORY = "business_directory"
    PUBLIC_RECORDS = "public_records"


class RemovalMode(str, Enum):
    AUTOMATED = "automated"
    PARTIAL = "partial"
    MANUAL = "manual"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class SourceDefinition:
    key: str
    name: str
    category: SourceCategory
    removal_mode: RemovalMode
    enabled: bool = False
    connector_name: str | None = None
    notes: str | None = None
    homepage_url: str | None = None
    search_url: str | None = None
    removal_url: str | None = None
    requires_human_verification: bool = False


SOURCES: tuple[SourceDefinition, ...] = (
    SourceDefinition(
        key="truecaller",
        name="Truecaller",
        category=SourceCategory.PHONE_LOOKUP,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.truecaller.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="beenverified",
        name="BeenVerified",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.beenverified.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="spokeo",
        name="Spokeo",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.spokeo.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="peoplefinders",
        name="PeopleFinders",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.peoplefinders.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="intelius",
        name="Intelius",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.intelius.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="usphonebook",
        name="USPhoneBook",
        category=SourceCategory.PHONE_LOOKUP,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.usphonebook.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="whitepages",
        name="Whitepages",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.whitepages.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="truthfinder",
        name="TruthFinder",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.truthfinder.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="instant_checkmate",
        name="Instant Checkmate",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.instantcheckmate.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="mylife",
        name="MyLife",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.mylife.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="fastpeoplesearch",
        name="FastPeopleSearch",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.fastpeoplesearch.com/",
        search_url="https://www.fastpeoplesearch.com/",
        removal_url="https://www.fastpeoplesearch.com/removal",
        requires_human_verification=True,
        notes="Use direct-site search and manual verification where required.",
    ),
    SourceDefinition(
        key="truepeoplesearch",
        name="TruePeopleSearch",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.truepeoplesearch.com/",
        search_url="https://www.truepeoplesearch.com/",
        removal_url="https://www.truepeoplesearch.com/removal",
        requires_human_verification=True,
        notes="Use direct-site search and manual verification where required.",
    ),
    SourceDefinition(
        key="radaris",
        name="Radaris",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://radaris.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="nuwber",
        name="Nuwber",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://nuwber.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="peekyou",
        name="PeekYou",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.peekyou.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="thatsthem",
        name="ThatsThem",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://thatsthem.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="clustrmaps",
        name="ClustrMaps",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://clustrmaps.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="familytreenow",
        name="FamilyTreeNow",
        category=SourceCategory.PEOPLE_SEARCH,
        removal_mode=RemovalMode.PARTIAL,
        homepage_url="https://www.familytreenow.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="zillow",
        name="Zillow",
        category=SourceCategory.PROPERTY_RECORDS,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://www.zillow.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="redfin",
        name="Redfin",
        category=SourceCategory.PROPERTY_RECORDS,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://www.redfin.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="facebook",
        name="Facebook",
        category=SourceCategory.SOCIAL,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://www.facebook.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="instagram",
        name="Instagram",
        category=SourceCategory.SOCIAL,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://www.instagram.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="linkedin",
        name="LinkedIn",
        category=SourceCategory.SOCIAL,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://www.linkedin.com/",
        requires_human_verification=True,
    ),
    SourceDefinition(
        key="google_maps",
        name="Google Maps",
        category=SourceCategory.BUSINESS_DIRECTORY,
        removal_mode=RemovalMode.MANUAL,
        homepage_url="https://maps.google.com/",
        requires_human_verification=True,
    ),
)


def get_source(
    key: str,
) -> SourceDefinition | None:
    for source in SOURCES:
        if source.key == key:
            return source

    return None


def list_sources() -> list[SourceDefinition]:
    return list(SOURCES)


def serialize_source(
    source: SourceDefinition,
) -> dict:
    return {
        "key": source.key,
        "name": source.name,
        "category": source.category.value,
        "removal_mode": source.removal_mode.value,
        "enabled": source.enabled,
        "connector_name": source.connector_name,
        "notes": source.notes,
        "homepage_url": source.homepage_url,
        "search_url": source.search_url,
        "removal_url": source.removal_url,
        "requires_human_verification": (
            source.requires_human_verification
        ),
    }