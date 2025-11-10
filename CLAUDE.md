# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TourBus is a web load-testing and stress-testing tool written in Ruby that combines complex test scenarios with scalable concurrent execution. It uses a hierarchical architecture where TourBus coordinates concurrent Guide threads that run Tourist test suites containing individual Tour methods.

## Key Commands

### Setup and Installation
```bash
# Install dependencies (requires Ruby 3.2.2)
bundle install

# Build and install gem locally (uses sudo)
ruby build.sh
```

### Running Tests
```bash
# Run all tourists once with 1 thread
tourbus

# Run with concurrency and repetitions
tourbus -c 4 -n 10 simple      # Run 'simple' tourist 10 times with 4 threads

# Run specific tours from a tourist
tourbus -c 2 simple -t homepage,login

# List all available tourists and their tours
tourbus -l -v

# Common options:
# -h, --host URL       Target host (default: http://localhost:3000)
# -c, --concurrency N  Number of concurrent threads
# -n, --number N       Total tourists to run
# -t, --tours NAMES    Specific tours to run (comma-separated)
# --dumpfile FILE      Output results file
# --touristsdir PATH   Path to tourists directory (default: ./tourists)
```

### Development Commands
```bash
# Monitor system processes during load tests
tourwatch -c 4

# HTTP proxy for capturing and generating tour files
tourproxy
```

## Architecture and Core Components

### Execution Hierarchy
- **TourBus** (`lib/tour_bus.rb`): Main coordinator that spawns Guide threads and collects statistics
- **Guide** (`lib/guide.rb`): Thread runner that selects and executes tourists
- **Tourist** (`lib/tourist.rb`): Base class for test suites, inherits from Minitest::Assertions and includes Webrat methods
- **Tours**: Individual test methods within a Tourist (prefixed with `tour_`)

### Key Design Patterns
- **Weighted Selection**: Tourists have a `tourist_weight` method (default 1) that determines selection probability
- **Object Pooling**: Tourist instances are cached and reused across runs for efficiency
- **Data Feeders**: CSV files in `./tourists/data/` can provide test data via `feed(:feeder_name)` method
- **Thread Safety**: Uses Monitor and Mutex for concurrent access to shared resources

### Tourist Definition
Tourists are Ruby classes in `./tourists/` directory that inherit from Tourist class. Example:

```ruby
class SimpleTourist < Tourist
  def tour_homepage
    visit "/"
    assert_match /Welcome/, response_body
  end

  def tour_login
    visit "/login"
    fill_in "Username", :with => "test@example.com"
    fill_in "Password", :with => "password"
    click_button "Sign In"
    assert_match /Dashboard/, response_body
  end
end
```

## Important Files and Locations

- **Tourist definitions**: `./tourists/*.rb`
- **Test data (CSV)**: `./tourists/data/*.csv`
- **Configuration**: `tourbus.yml` (searches multiple locations)
- **Core library**: `lib/` directory
- **Example app**: `examples/contact_app/` (Sinatra app with sample tourists)

## Configuration

TourBus searches for `tourbus.yml` in order:
1. `./tourists/tourbus.yml`
2. `./tourbus.yml`
3. `./config/tourbus.yml`
4. `~/tourbus.yml`

Configuration options mirror command-line flags:
```yaml
host: http://localhost:3000
concurrency: 4
number: 100
rand: 12345  # For reproducible runs
```

## Development Notes

### Ruby Version
Currently using Ruby 3.2.2 (upgraded from original 1.9.3). Check `.ruby-version` file.

### Dependencies
Key gems: mechanize (≥1.0.0), webrat (≥0.7.0), faker, optimist, activesupport, minitest

### Testing Framework
The project uses Minitest assertions within Tourist classes. There are minimal specs in `spec/` directory that need expansion.

### Recent Development Focus
- Rate limiting detection and logging
- Ruby modernization and deprecation fixes
- CSV data validation improvements
- Tourist caching optimizations

### Known Issues
- Pluralized tour names don't work due to Rails inflection bugs
- Webrat has session issues with Sinatra apps
- Limited test coverage of the framework itself

## Common Development Tasks

### Adding a New Tourist
1. Create a new file in `./tourists/` directory
2. Define a class inheriting from `Tourist`
3. Add `tour_*` methods for each test scenario
4. Use Webrat DSL methods (visit, fill_in, click_button, etc.)
5. Use Minitest assertions for validations

### Using CSV Data
1. Place CSV files in `./tourists/data/`
2. First row must be headers
3. Access in tourist with: `row = feed(:filename_without_csv)`
4. Example: `feed(:users)` loads from `./tourists/data/users.csv`

### Debugging
- Add `require 'pry'; binding.pry` for breakpoints
- Use `-v` flag for verbose output
- Check `--dumpfile stdout` to see all tour results
- Monitor with `tourwatch` during load tests