# gh-switch Test Suite

Automated testing for the GitHub account switcher skill using Giskard OSS.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Ensure prerequisites are met:
   - Both GitHub accounts authenticated with `gh auth login`
   - SSH keys configured for both accounts
   - Script has execution permissions

## Running Tests

Run all tests:
```bash
python tests/test_gh_switch.py
```

## Test Scenarios

The test suite includes:

1. **Status Check** - Verifies the script shows current account status
2. **Switch to Work** - Tests switching to work account (haifeng-li_sfemu)
3. **Switch to Personal** - Tests switching to personal account (haifeng-li-at-salesforce)
4. **Invalid Account** - Validates error handling for invalid account names
5. **Account Persistence** - Confirms switch persists across invocations

## Test Output

Each test scenario reports:
- ✅ Pass/Fail status
- Assertions checked
- Output from the script
- Summary at the end

## Adding New Tests

To add a new test scenario:

1. Create an async test function:
```python
async def test_your_scenario():
    scenario = (
        Scenario("test_name")
        .interact(
            inputs="your_input",
            outputs=run_switch_script,
        )
        .assert_that(
            lambda trace: "expected" in trace.last.outputs,
            name="description of assertion"
        )
    )
    result = await scenario.run()
    result.print_report()
    return result
```

2. Add it to the `tests` list in `run_all_tests()`

## About Giskard OSS

Giskard is an open-source evaluation framework for AI agents. Learn more:
- GitHub: https://github.com/Giskard-AI/giskard
- Docs: https://docs.giskard.ai
