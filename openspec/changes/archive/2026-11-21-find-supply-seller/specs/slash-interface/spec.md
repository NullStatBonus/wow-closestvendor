# Spec Delta

## ADDED Requirements

### Requirement: Find command
`/cvn find <item link or name>` SHALL run the supply-search lookup. With no text it SHALL print its usage and change nothing. `/cvn help` SHALL list it. It SHALL write no setting.

#### Scenario: Find with text
- **WHEN** `/cvn find` is used with an item name
- **THEN** the lookup runs as supply-search describes and no setting changes

#### Scenario: Find without text
- **WHEN** `/cvn find` is used with no text
- **THEN** chat shows how to use it and nothing opens
