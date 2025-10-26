# Media Health Check PRD - Review Guide

**Purpose:** This guide helps you review the PRD systematically and provide focused feedback.

---

## Quick Review Checklist

Use this checklist to ensure you've reviewed all critical aspects:

- [ ] **Goals align with your vision** - Does this solve your problem?
- [ ] **Scope is appropriate** - Right balance of features for MVP?
- [ ] **Technical approach makes sense** - Architecture fits your needs?
- [ ] **Extensibility strategy** - Can you add ebooks/music later easily?
- [ ] **Open questions answered** - Do you have opinions on the Q1-Q7?
- [ ] **Missing requirements** - Anything you need that isn't included?

---

## Review by Section

### 1. Executive Summary & Problem Statement

**Key Questions:**
- Does this accurately describe your current challenges?
- Is the value proposition compelling and clear?
- Any pain points we missed?

**Feedback Template:**
```
✓ Accurately describes my needs
✗ Missing: [describe what's missing]
? Unclear: [what needs clarification]
```

---

### 2. Goals and Scope

**Current MVP Scope:**
- Movies validation (naming, structure)
- TV Shows validation (naming, structure)
- Console + CSV + JSON reporting
- Configuration file-based

**Discussion Points:**

**For MVP (Phase 1), would you also want:**
- [ ] Duplicate file detection?
- [ ] File size/quality checks?
- [ ] Sample file detection?
- [ ] Subtitle validation?
- [ ] NFO file validation?

**What's your priority order?**
1. _______________________
2. _______________________
3. _______________________

**Out of scope items - Do you agree?**
- Auto-remediation (fixing issues) - Keep separate or add?
- Metadata editing - Out of scope or needed?
- Content downloading - Definitely out of scope?

---

### 3. Functional Requirements Deep Dive

#### Movies Validation - Missing anything?

**Current checks:**
- Folder naming: `Movie Title (Year)/`
- File naming: `Movie Title (Year).ext`
- One movie per folder
- No extra subdirectories
- Empty folder detection

**Should we add:**
- [ ] Multiple video files for different qualities (e.g., 4K + 1080p)?
- [ ] Extras folder validation (trailers, behind-the-scenes)?
- [ ] Multi-part movies (CD1, CD2)?
- [ ] Collections/franchises structure?

#### TV Shows Validation - Missing anything?

**Current checks:**
- Show naming: `Show Name (Year)/`
- Season naming: `Season ##/`
- Episode naming: `Show Name - S##E## - Episode Title.ext`
- Hierarchy verification
- Empty folder detection

**Should we add:**
- [ ] Multi-episode files (S01E01-E02)?
- [ ] Specials folder (Season 00) validation?
- [ ] Multi-season packs structure?
- [ ] Missing episode detection (S01E01, S01E03 but no E02)?
- [ ] Anime naming support (different conventions)?

---

### 4. Technical Architecture

**Proposed Stack:**
- Language: PowerShell
- Modular design with plugins
- Configuration: JSON
- Outputs: Console, CSV, JSON

**Questions:**

**Q: PowerShell as the implementation language?**
- ✓ Pros: Native to Windows, good file handling, you're familiar
- ✗ Cons: Less portable to Linux/Mac, harder to contribute
- Alternative: Python? C#?
- **Your preference:** _______________________

**Q: Configuration format?**
```
Option A: JSON (structured, widely supported)
{
  "libraries": {
    "movies": { "path": "...", "enabled": true }
  }
}

Option B: YAML (more readable, comments allowed)
libraries:
  movies:
    path: "..."
    enabled: true

Option C: PowerShell config (native, programmable)
$Config = @{
    Libraries = @{
        Movies = @{ Path = "..."; Enabled = $true }
    }
}
```
**Your preference:** _______________________

**Q: Validator plugin discovery?**
- Automatic scanning of validators/ folder?
- Explicit registration in config?
- Hybrid approach?

---

### 5. Reporting & Output

**Current proposal:**
- Console output with colors
- CSV export for spreadsheet analysis
- JSON export for programmatic processing

**Questions:**

**What's your primary use case?**
- [ ] Quick console scan to see if there are issues
- [ ] Export to CSV to work through issues systematically
- [ ] Automated monitoring with JSON parsing
- [ ] All of the above

**Console output - What detail level?**
```
Option A: Summary only
✓ Movies: 245 OK, 5 issues
✗ TV Shows: 1820 OK, 12 issues

Option B: Full listing
✓ The Matrix (1999) - OK
✗ Dark Knight (2008) - Missing year in file
✓ Inception (2010) - OK
...

Option C: Issues only
✗ Dark Knight (2008) - Missing year in file
✗ Avatar - Missing year in folder
```
**Your preference:** _______________________

**CSV format - What columns?**
Current proposal:
```csv
MediaType,Path,IssueType,Severity,Description,Recommendation
Movie,A:\Movies\Avatar,movie.folder.missing-year,Critical,"Missing year","Add (2009)"
```

**Want to add:**
- [ ] Timestamp
- [ ] File size
- [ ] Last modified date
- [ ] Quick fix command
- [ ] Other: _______________________

---

### 6. Extensibility & Future Growth

**Your planned media expansion:**
1. Movies ✓ (now)
2. TV Shows ✓ (now)
3. _______________________ (next)
4. _______________________ (future)
5. _______________________ (future)

**For Ebooks specifically:**

**Which standard do you want to follow?**
- [ ] Calibre format: `Author/Book Title/Book Title.epub`
- [ ] Readarr format: `Author/Book Title (Year)/Book Title.epub`
- [ ] Custom: _______________________

**For Music (if planned):**
- [ ] Plex format: `Artist/Album/01 - Track.mp3`
- [ ] Lidarr format: Similar to above
- [ ] Not planning music: _______

**Plugin architecture - Concerns?**
- Do you plan to write custom validators yourself?
- Should third-party validators be supported?
- Need validator marketplace/sharing?

---

### 7. Performance & Scale

**Your current library size:**
- Movies: _______ items
- TV Shows: _______ shows, _______ episodes
- Expected growth: _______ items/year

**Performance expectations:**
- Acceptable scan time for full library: _______
- Run frequency: Daily / Weekly / Monthly / On-demand
- Can it block other operations? Yes / No
- Run in background? Yes / No

**Large library considerations:**
If you have 10K+ movies or 50K+ episodes:
- [ ] Need parallel/multi-threaded scanning?
- [ ] Need incremental scanning (only changed files)?
- [ ] Need progress saving (resume after crash)?
- [ ] Need scan scheduling/throttling?

---

### 8. Testing Strategy

**How much testing do you want?**

**Option A: Heavy testing (80% coverage, TDD approach)**
- Pros: Very robust, catches bugs early, easier to refactor
- Cons: Slower initial development, more upfront work

**Option B: Moderate testing (focus on critical paths)**
- Pros: Faster development, still catches major issues
- Cons: Some edge cases may slip through

**Option C: Light testing (manual testing mostly)**
- Pros: Fastest development
- Cons: More bugs in production, harder to maintain

**Your preference:** _______________________

**Would you run the tests regularly?**
- Yes, before every use
- Yes, during development only
- Probably not
- Not sure

---

### 9. Open Questions - Your Answers

Please provide your thoughts on each:

**Q1: Configuration Format**
```
Your choice: JSON / YAML / PowerShell
Reasoning: ___________________________________________
```

**Q2: Issue Remediation**
```
Should health check fix issues automatically?
□ No, read-only reports only (safer)
□ Yes, with --fix flag (convenient)
□ Yes, with interactive confirmation
□ Separate tool for fixes (my preference)

Reasoning: ___________________________________________
```

**Q3: Historical Tracking**
```
Track issues over time?
□ No, just current state reports (simpler)
□ Yes, in database (SQLite, etc.)
□ Yes, in JSON files (easier)
□ Not sure, decide later

Reasoning: ___________________________________________
```

**Q4: Validation Strictness**
```
Configurable strictness levels?
□ No, one standard for all (simpler)
□ Yes, strict/lenient modes (flexible)
□ Yes, per-library settings (most flexible)

Example use case: ___________________________________
```

**Q5: Performance vs. Completeness**
```
Parallel scanning for large libraries?
□ Yes, essential for my library size
□ Nice to have, but not critical
□ No, sequential is fine

Library size: __________ items
```

**Q6: Cross-Platform Support**
```
Target platforms:
□ Windows only (what I use)
□ Windows + Linux (future proofing)
□ Windows + Linux + macOS (max compatibility)

Current need: ___________
Future need: ___________
```

**Q7: Versioning Strategy**
```
How to handle breaking changes in validators?
□ Lock validators to core version (strict)
□ Semantic versioning with compatibility checks
□ Best effort, community-driven
□ Not sure, not a priority

Reasoning: ___________________________________________
```

---

## Additional Considerations

### Missing Features?

**Is there anything critical we haven't covered?**

Examples:
- Notification system (email when issues found)?
- Web dashboard for viewing reports?
- Integration with Plex API?
- Integration with *arr tools?
- Automatic issue prioritization?
- Export issues to task management system?
- Other: ___________________________________________

### User Experience

**How do you envision using this tool?**

**Scenario 1: After bulk operations**
```
I just renamed 200 movies. I want to:
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________
```

**Scenario 2: Regular maintenance**
```
Every week, I want to:
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________
```

**Scenario 3: Adding new content**
```
After adding new movies/shows, I want to:
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________
```

### Deal Breakers

**Are there any must-haves for MVP?**

Must have in Phase 1:
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

Can wait for Phase 2:
1. _________________________________________________
2. _________________________________________________

---

## Prioritization Exercise

**Rank these features by importance (1 = most important):**

- [ ] ___ Movie folder/file naming validation
- [ ] ___ TV show folder/file naming validation
- [ ] ___ Structure validation (hierarchy checks)
- [ ] ___ Empty folder detection
- [ ] ___ Duplicate detection
- [ ] ___ Sample file detection
- [ ] ___ Quality checks (resolution, codec)
- [ ] ___ Missing episode detection
- [ ] ___ CSV export
- [ ] ___ JSON export
- [ ] ___ HTML report
- [ ] ___ Configuration file support
- [ ] ___ Performance optimization (parallel scan)
- [ ] ___ Extensibility (plugin architecture)
- [ ] ___ Testing suite

**Top 5 for MVP:**
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________
4. _________________________________________________
5. _________________________________________________

---

## Implementation Preferences

### Development Approach

**Preferred methodology:**
- [ ] Test-Driven Development (write tests first)
- [ ] Test-After Development (working code, then tests)
- [ ] Iterative (basic version, then add tests)

**Development pace:**
- [ ] Fast MVP - get something working quickly, refine later
- [ ] Balanced - working + clean code + basic tests
- [ ] Robust - comprehensive testing, documentation, polish

### Code Style

**Preferences:**
- Verbosity: Explicit/verbose ← → Concise/terse
- Comments: Heavy ← → Minimal (self-documenting code)
- Error handling: Fail-fast ← → Graceful degradation
- Documentation: Extensive ← → Essential only

---

## Next Steps After Review

Once you've provided feedback, we'll:

1. **Refine the PRD** based on your input
2. **Create a Technical Design Document** with:
   - Detailed class/module designs
   - API specifications
   - Data flow diagrams
   - Validation algorithms
3. **Set up project structure** and development environment
4. **Implement MVP iteratively** with:
   - Week 1: Core framework + Movie validator
   - Week 2: TV Show validator + Reporting
   - Week 3: Testing + Polish
5. **Test with your real library**
6. **Iterate based on real-world usage**

---

## Feedback Submission

**Please provide feedback in any format:**

1. **Inline comments** on the PRD itself
2. **Answers to questions** in this review guide
3. **Free-form feedback** - what excites you, what concerns you
4. **Use cases** we haven't considered
5. **Priority changes** - what's more/less important than we thought

**Key areas we need your input:**
- ✓ Open questions Q1-Q7 answers
- ✓ MVP feature prioritization
- ✓ Missing requirements
- ✓ Technical preferences (language, config format)
- ✓ Use case scenarios

---

**Ready to proceed?** Once you provide feedback, we'll create the Technical Design Document and begin implementation!
