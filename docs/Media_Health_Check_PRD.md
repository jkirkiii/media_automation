# Product Requirements Document: Media Health Check System

**Version:** 1.0-DRAFT
**Created:** 2025-10-12
**Status:** Draft - Awaiting Review
**Owner:** Media Automation Project

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Goals and Objectives](#goals-and-objectives)
4. [Scope](#scope)
5. [User Stories](#user-stories)
6. [Functional Requirements](#functional-requirements)
7. [Non-Functional Requirements](#non-functional-requirements)
8. [Technical Architecture](#technical-architecture)
9. [Data Models and Standards](#data-models-and-standards)
10. [Extensibility Strategy](#extensibility-strategy)
11. [Testing Strategy](#testing-strategy)
12. [Future Considerations](#future-considerations)
13. [Success Metrics](#success-metrics)
14. [Open Questions](#open-questions)

---

## 1. Executive Summary

The Media Health Check System is a modular, extensible tool designed to validate and report on the structural integrity and naming compliance of a Plex media server library. The system will initially support Movies and TV Shows, with a plugin-based architecture allowing for future expansion to support ebooks, audiobooks, music, and other media types.

**Core Value Proposition:**
- Proactive detection of naming and structural issues
- Automated compliance checking against Plex/Sonarr/Radarr standards
- Extensible architecture for growing media libraries
- Regular health monitoring for maintaining library quality

---

## 2. Problem Statement

### Current Challenges

1. **Manual Validation is Time-Consuming**
   - Checking hundreds of movies and TV shows manually is impractical
   - No automated way to detect when new content violates naming standards
   - Difficult to verify library integrity after bulk operations

2. **Multiple Standards to Track**
   - Movies follow different naming conventions than TV shows
   - Different media types require different validation rules
   - Plex/automation tools have specific requirements

3. **Growing Library Complexity**
   - Library will expand to include ebooks, audiobooks, music
   - Each media type has unique structural requirements
   - Need consistent approach across all media types

4. **No Proactive Monitoring**
   - Issues are discovered reactively when Plex fails to recognize content
   - No regular health checks to maintain library quality
   - Difficult to identify trends or recurring problems

### Impact

Without a health check system:
- Metadata matching failures in Plex
- Automation tools (Sonarr/Radarr) may not recognize content
- Manual fixes required for each issue
- Risk of data loss or corruption during bulk operations
- Difficult to maintain consistency as library grows

---

## 3. Goals and Objectives

### Primary Goals

1. **Validate Naming Compliance**
   - Ensure all media follows Plex/automation naming standards
   - Detect deviations from expected patterns
   - Report specific issues with actionable recommendations

2. **Verify Structural Integrity**
   - Confirm directory hierarchies are correct
   - Detect missing or misplaced files
   - Identify empty or orphaned directories

3. **Enable Extensibility**
   - Support multiple media types through plugin architecture
   - Allow easy addition of new media types
   - Maintain consistent interface across all validators

4. **Provide Actionable Reports**
   - Generate clear, detailed health reports
   - Categorize issues by severity
   - Provide remediation suggestions

### Secondary Goals

1. **Automation Integration**
   - Support scheduled/automated execution
   - Generate machine-readable reports (JSON/CSV)
   - Enable integration with monitoring systems

2. **Performance**
   - Scan large libraries efficiently
   - Minimize resource usage
   - Support incremental/partial scans

3. **Maintainability**
   - Clean, testable code architecture
   - Comprehensive documentation
   - Easy to update standards/rules

---

## 4. Scope

### In Scope - Phase 1 (MVP)

**Media Types:**
- ✅ Movies
- ✅ TV Shows

**Validation Types:**
- ✅ Folder naming compliance
- ✅ File naming compliance
- ✅ Directory structure verification
- ✅ Basic completeness checks

**Reporting:**
- ✅ Console output with color coding
- ✅ CSV export of issues
- ✅ Summary statistics

**Standards:**
- ✅ Plex naming conventions
- ✅ Sonarr/Radarr compatibility

### In Scope - Future Phases

**Phase 2 - Extended Media:**
- 📚 Ebooks (Calibre/Readarr standards)
- 🎵 Music (Plex/Lidarr standards)
- 🎧 Audiobooks
- 📸 Photos/Videos (personal media)

**Phase 3 - Advanced Features:**
- 🔍 Duplicate detection
- 📊 Quality analysis (resolution, codec)
- 🏷️ Metadata validation
- 🔗 Cross-reference checking (missing episodes, etc.)
- ⚡ Performance profiling

**Phase 4 - Automation & Integration:**
- 🤖 Auto-remediation capabilities
- 📧 Email/notification support
- 📈 Trend analysis and reporting
- 🔌 API for external tools

### Out of Scope

- ❌ Actual file renaming/moving (separate tool)
- ❌ Metadata editing
- ❌ Media transcoding or conversion
- ❌ Content downloading or acquisition
- ❌ User authentication/permissions (single-user tool)

---

## 5. User Stories

### As a media server administrator, I want to...

**US-1: Basic Health Check**
```
Given I have a media library with movies and TV shows
When I run the health check script
Then I receive a report showing all naming and structural issues
And the report categorizes issues by severity (Critical, Warning, Info)
```

**US-2: Scheduled Monitoring**
```
Given I want to maintain library health over time
When I schedule the health check to run weekly
Then I receive regular reports showing any new issues
And I can track library health trends
```

**US-3: Post-Operation Validation**
```
Given I have just completed a bulk rename operation
When I run the health check
Then I can verify all files were renamed correctly
And identify any issues that need manual intervention
```

**US-4: New Media Type Addition**
```
Given I want to add ebook monitoring to my library
When I add an ebook validator plugin
Then the health check automatically includes ebook validation
And follows the same reporting format as other media types
```

**US-5: Focused Scanning**
```
Given I only want to check a specific show or movie
When I run the health check with a filter
Then only the specified media is scanned
And the report focuses on that subset
```

---

## 6. Functional Requirements

### FR-1: Core Framework

**FR-1.1: Configuration System**
- Load configuration from file (JSON/YAML)
- Define media library paths
- Specify enabled validators
- Configure output formats
- Support environment-specific configs

**FR-1.2: Validator Plugin Architecture**
- Define standard validator interface
- Support dynamic validator loading
- Allow validators to be enabled/disabled
- Provide validator registration mechanism

**FR-1.3: Reporting Engine**
- Collect issues from all validators
- Categorize by severity (Critical, Warning, Info)
- Generate multiple output formats
- Support filtering and sorting

### FR-2: Movie Validation

**FR-2.1: Movie Folder Naming**
- Pattern: `Movie Title (Year)/`
- Validate year is 4 digits
- Check for illegal characters
- Detect missing year tags
- Flag multiple movies in same folder

**FR-2.2: Movie File Naming**
- Pattern: `Movie Title (Year).ext`
- Validate file matches folder name
- Check for standard video extensions
- Detect duplicate files
- Flag movies without year in filename

**FR-2.3: Movie Structure**
- Verify one movie per folder
- Check for proper nesting (no extra subdirectories for single movies)
- Detect empty movie folders
- Identify junk files (samples, .nfo, etc.)

### FR-3: TV Show Validation

**FR-3.1: Show Folder Naming**
- Pattern: `Show Name (Year)/`
- Validate year is 4 digits
- Check for illegal characters
- Detect missing year tags

**FR-3.2: Season Folder Naming**
- Pattern: `Season ##/` (zero-padded)
- Validate sequential season numbers
- Detect non-standard naming (e.g., "Season 1" vs "Season 01")
- Flag shows without season folders

**FR-3.3: Episode File Naming**
- Pattern: `Show Name - S##E## - Episode Title.ext`
- Validate season/episode numbers
- Check episode numbering sequence
- Detect duplicate episodes
- Flag missing episode titles

**FR-3.4: TV Structure**
- Verify show → season → episode hierarchy
- Check for orphaned files
- Detect empty season folders
- Identify incomplete seasons (optional)

### FR-4: Reporting & Output

**FR-4.1: Console Output**
- Color-coded severity levels
- Progress indicators during scan
- Summary statistics at end
- Real-time issue display

**FR-4.2: CSV Export**
- One row per issue
- Columns: MediaType, Path, IssueType, Severity, Description, Recommendation
- Sortable and filterable in Excel

**FR-4.3: JSON Export**
- Machine-readable format
- Structured issue hierarchy
- Metadata about scan (timestamp, duration, counts)
- Supports programmatic processing

**FR-4.4: HTML Report** (Future)
- Visual dashboard
- Charts and graphs
- Interactive filtering
- Drill-down capability

### FR-5: Execution Modes

**FR-5.1: Full Scan**
- Scan all configured media libraries
- Run all enabled validators
- Generate complete report

**FR-5.2: Partial Scan**
- Filter by media type (movies only, TV only)
- Filter by path/folder
- Filter by specific show/movie

**FR-5.3: Incremental Scan** (Future)
- Only scan changed files since last run
- Compare against baseline
- Report new issues only

**FR-5.4: Dry Run**
- Show what would be scanned
- Display configuration
- No actual validation performed

---

## 7. Non-Functional Requirements

### NFR-1: Performance

- **NFR-1.1**: Scan 1000 movies in under 2 minutes
- **NFR-1.2**: Scan 100 TV shows (1000+ episodes) in under 5 minutes
- **NFR-1.3**: Memory usage < 500MB for typical library (10K items)
- **NFR-1.4**: Support libraries up to 50K items without degradation

### NFR-2: Reliability

- **NFR-2.1**: Handle missing directories gracefully (no crashes)
- **NFR-2.2**: Continue scanning after encountering errors
- **NFR-2.3**: Validate configuration before starting scan
- **NFR-2.4**: Provide clear error messages for all failures

### NFR-3: Maintainability

- **NFR-3.1**: Code coverage > 80% for core modules
- **NFR-3.2**: All public functions have documentation
- **NFR-3.3**: Modular design with clear separation of concerns
- **NFR-3.4**: Follow language style guide (PSScriptAnalyzer for PowerShell)

### NFR-4: Extensibility

- **NFR-4.1**: New media type can be added without modifying core
- **NFR-4.2**: Validators can be independently developed and tested
- **NFR-4.3**: Configuration format supports future expansion
- **NFR-4.4**: Plugin architecture allows third-party validators

### NFR-5: Usability

- **NFR-5.1**: Single command execution with sensible defaults
- **NFR-5.2**: Clear, actionable error messages
- **NFR-5.3**: Progress indication for long-running scans
- **NFR-5.4**: Help documentation accessible via `-Help` flag

---

## 8. Technical Architecture

### 8.1 High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                    CLI Interface                        │
│  (Start-MediaHealthCheck.ps1)                          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│              Core Framework                             │
│  - Configuration Manager                                │
│  - Validator Registry                                   │
│  - Scan Orchestrator                                    │
│  - Issue Collector                                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌─────────────┐
│   Movie      │  │   TV Show    │  │   Ebook     │
│  Validator   │  │  Validator   │  │  Validator  │
│              │  │              │  │  (Future)   │
└──────────────┘  └──────────────┘  └─────────────┘
        │                 │
        └────────┬────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│              Reporting Engine                           │
│  - Console Reporter                                     │
│  - CSV Exporter                                         │
│  - JSON Exporter                                        │
└─────────────────────────────────────────────────────────┘
```

### 8.2 Module Structure

```
media_automation/
├── scripts/
│   └── health-check/
│       ├── Start-MediaHealthCheck.ps1      # Main entry point
│       ├── core/
│       │   ├── HealthCheckCore.psm1        # Core framework
│       │   ├── ConfigManager.psm1          # Configuration handling
│       │   ├── IssueCollector.psm1         # Issue aggregation
│       │   └── ValidatorBase.psm1          # Base validator class
│       ├── validators/
│       │   ├── MovieValidator.psm1         # Movie-specific checks
│       │   ├── TVShowValidator.psm1        # TV show-specific checks
│       │   └── README.md                   # Validator development guide
│       ├── reporters/
│       │   ├── ConsoleReporter.psm1        # Console output
│       │   ├── CsvReporter.psm1            # CSV export
│       │   └── JsonReporter.psm1           # JSON export
│       └── utils/
│           ├── PathHelpers.psm1            # Path manipulation
│           └── NamingPatterns.psm1         # Regex patterns
├── configs/
│   └── health-check-config.json            # Default configuration
└── tests/
    └── health-check/
        ├── unit/                            # Unit tests
        └── integration/                     # Integration tests
```

### 8.3 Key Interfaces

**IValidator Interface:**
```powershell
interface IValidator {
    [string] GetName()
    [string] GetDescription()
    [string[]] GetSupportedMediaTypes()
    [Issue[]] Validate([string] $Path, [hashtable] $Config)
}
```

**Issue Model:**
```powershell
class Issue {
    [string] $MediaType
    [string] $Path
    [string] $IssueType
    [string] $Severity      # Critical, Warning, Info
    [string] $Description
    [string] $Recommendation
    [datetime] $DetectedAt
}
```

**Configuration Model:**
```json
{
  "libraries": {
    "movies": {
      "path": "A:\\Media\\Movies",
      "enabled": true,
      "validators": ["naming", "structure"]
    },
    "tvshows": {
      "path": "A:\\Media\\TV Shows",
      "enabled": true,
      "validators": ["naming", "structure", "completeness"]
    }
  },
  "output": {
    "console": true,
    "csv": "./health-report.csv",
    "json": "./health-report.json"
  },
  "options": {
    "ignoreHiddenFiles": true,
    "ignoreJunkFiles": [".nfo", ".txt", "sample"],
    "maxIssuesPerItem": 10
  }
}
```

---

## 9. Data Models and Standards

### 9.1 Naming Standards Reference

**Movies:**
```
Standard:     Movie Title (Year)/Movie Title (Year).ext
Example:      The Matrix (1999)/The Matrix (1999).mkv
Variations:   Movie Title (Year)/Movie Title (Year) - [Quality].ext
```

**TV Shows:**
```
Standard:     Show Name (Year)/Season ##/Show Name - S##E## - Episode Title.ext
Example:      Breaking Bad (2008)/Season 01/Breaking Bad - S01E01 - Pilot.mkv
Special:      Show Name (Year)/Season 00/Show Name - S00E01 - Special.ext
```

**Ebooks (Future):**
```
Standard:     Author/Book Title (Year)/Book Title.ext
Example:      Isaac Asimov/Foundation (1951)/Foundation.epub
Series:       Author/Series Name/## - Book Title (Year)/Book Title.ext
```

### 9.2 Issue Taxonomy

**Severity Levels:**
- **Critical**: Prevents automation tools from recognizing content
- **Warning**: May cause issues but content is still recognizable
- **Info**: Best practice violations, cosmetic issues

**Issue Types:**

*Movies:*
- `movie.folder.missing-year`: Movie folder lacks year tag
- `movie.folder.invalid-characters`: Folder name has illegal characters
- `movie.file.name-mismatch`: File name doesn't match folder
- `movie.structure.multiple-files`: Multiple video files in folder
- `movie.structure.empty-folder`: Movie folder with no video files

*TV Shows:*
- `tv.show.missing-year`: Show folder lacks year tag
- `tv.season.invalid-format`: Season folder not "Season ##" format
- `tv.episode.invalid-format`: Episode file doesn't match S##E## pattern
- `tv.episode.missing-title`: Episode file lacks episode title
- `tv.structure.orphaned-file`: Video file not in season folder
- `tv.structure.empty-season`: Season folder with no episodes

---

## 10. Extensibility Strategy

### 10.1 Plugin Architecture

**Validator Discovery:**
1. Scan `validators/` directory for `.psm1` files
2. Load modules that implement `IValidator` interface
3. Register validators with core framework
4. Enable/disable via configuration

**Adding New Media Type:**
```powershell
# Example: EbookValidator.psm1
class EbookValidator : IValidator {
    [string] GetName() { return "Ebook" }
    [string[]] GetSupportedMediaTypes() { return @("ebook") }

    [Issue[]] Validate([string] $Path, [hashtable] $Config) {
        # Ebook-specific validation logic
        return $issues
    }
}
```

### 10.2 Configuration Extension

**Adding New Library Type:**
```json
{
  "libraries": {
    "ebooks": {
      "path": "D:\\Media\\Books",
      "enabled": true,
      "standard": "calibre",
      "validators": ["naming", "structure", "metadata"]
    }
  }
}
```

### 10.3 Reporter Extension

**Custom Reporter Example:**
```powershell
class EmailReporter : IReporter {
    [void] Generate([Issue[]] $Issues, [hashtable] $Config) {
        # Send email with issues summary
    }
}
```

---

## 11. Testing Strategy

### 11.1 Test Pyramid

```
        /\
       /  \     E2E Tests (5%)
      /────\    - Full library scans
     /      \   - Real-world scenarios
    /────────\  Integration Tests (25%)
   /          \ - Validator combinations
  /────────────\ Unit Tests (70%)
 /              \ - Individual functions
/________________\ - Edge cases
```

### 11.2 Test Coverage Goals

**Unit Tests:**
- All validator functions: 100%
- Core framework: 90%
- Utilities: 85%
- Overall: 80%

**Test Fixtures:**
```
tests/fixtures/
├── movies/
│   ├── valid/
│   │   └── The Matrix (1999)/
│   │       └── The Matrix (1999).mkv
│   └── invalid/
│       ├── Missing Year Movie/
│       └── Bad[Characters] (2020)/
└── tvshows/
    ├── valid/
    │   └── Breaking Bad (2008)/
    │       └── Season 01/
    │           └── Breaking Bad - S01E01 - Pilot.mkv
    └── invalid/
        └── Show Without Year/
```

### 11.3 Test Scenarios

**Movie Validator Tests:**
- ✓ Valid movie naming
- ✓ Missing year tag
- ✓ Invalid characters in name
- ✓ Multiple video files
- ✓ Empty movie folder
- ✓ File/folder name mismatch
- ✓ Year format validation

**TV Validator Tests:**
- ✓ Valid show structure
- ✓ Missing year tag
- ✓ Invalid season naming
- ✓ Invalid episode naming
- ✓ Missing episode titles
- ✓ Orphaned files
- ✓ Empty seasons
- ✓ Episode numbering gaps

---

## 12. Future Considerations

### 12.1 Phase 2 Features

**Advanced Validation:**
- Duplicate detection (same movie in multiple folders)
- Quality checks (resolution, codec, bitrate)
- Metadata validation (TMDb/TVDb matching)
- Subtitle file validation
- Extras organization (trailers, behind-the-scenes)

**Reporting Enhancements:**
- HTML dashboard with charts
- Trend analysis over time
- Issue history tracking
- Before/after comparisons

**Performance Optimizations:**
- Parallel scanning
- Incremental scans (only changed files)
- Caching validation results
- Database for historical data

### 12.2 Integration Opportunities

**Plex Integration:**
- Validate against Plex library
- Compare health check results with Plex metadata
- Identify unmatched content

**Sonarr/Radarr Integration:**
- Export issues in format compatible with *arr tools
- Trigger re-scans when issues fixed
- Validate against *arr naming templates

**Monitoring Tools:**
- Prometheus metrics export
- Grafana dashboard templates
- Alert integration (email, Slack, Discord)

### 12.3 AI/ML Opportunities

**Future Enhancements:**
- Suggest correct naming based on file analysis
- Learn from user corrections
- Predict likely metadata matches
- Anomaly detection

---

## 13. Success Metrics

### 13.1 Adoption Metrics

- Script execution frequency (target: weekly)
- Number of media items scanned per execution
- Time to complete full scan (target: < 10 minutes for 10K items)

### 13.2 Quality Metrics

- Issues detected per scan
- Critical issues vs. warnings ratio
- Time to remediate detected issues
- Reduction in Plex metadata failures

### 13.3 Code Quality Metrics

- Test coverage (target: > 80%)
- Code complexity (target: cyclomatic < 10)
- Documentation coverage (target: 100% public APIs)
- Bug escape rate (issues found in production)

---

## 14. Open Questions

### Questions for Discussion

**Q1: Configuration Format**
- Should we use JSON, YAML, or PowerShell-based config?
- Pros/Cons of each approach?

**Q2: Issue Remediation**
- Should health check script offer to fix issues automatically?
- Or keep it read-only with separate remediation tools?

**Q3: Historical Tracking**
- Should we track issues over time in a database?
- Or keep it stateless with file-based reports only?

**Q4: Validation Strictness**
- Should validators be configurable for strict vs. lenient mode?
- Different strictness levels for different libraries?

**Q5: Performance vs. Completeness**
- Should we support parallel scanning for large libraries?
- Trade-offs between speed and resource usage?

**Q6: Cross-Platform Support**
- Should this work on Linux/macOS or Windows-only?
- Impact on path handling and file operations?

**Q7: Versioning Strategy**
- How should we handle breaking changes in validators?
- Version compatibility between core and plugins?

---

## Appendix A: References

- [Plex Naming Conventions](https://support.plex.tv/articles/naming-and-organizing-your-tv-show-files/)
- [Sonarr Episode Naming](https://wiki.servarr.com/sonarr/settings#episode-naming)
- [Radarr Movie Naming](https://wiki.servarr.com/radarr/settings#movie-naming)
- [FileBot Naming Formats](https://www.filebot.net/naming.html)

## Appendix B: Glossary

- **Media Type**: Category of content (Movie, TV Show, Ebook, etc.)
- **Validator**: Module that checks specific aspects of media health
- **Issue**: A detected problem with naming or structure
- **Severity**: Classification of issue importance (Critical, Warning, Info)
- **Health Check**: Full scan and validation of media library

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0-DRAFT | 2025-10-12 | Media Automation | Initial draft for review |

---

## Next Steps

1. **Review this PRD** with stakeholder (you!)
2. **Refine requirements** based on feedback
3. **Prioritize features** for MVP
4. **Create technical design document**
5. **Begin implementation** with TDD approach

---

**Status:** 📝 AWAITING REVIEW - Please provide feedback on:
- Missing requirements or use cases
- Technical approach concerns
- Prioritization of features
- Open questions above
