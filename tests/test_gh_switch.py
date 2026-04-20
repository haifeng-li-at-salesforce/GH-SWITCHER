"""
Test suite for gh-switch skill using Giskard OSS
"""
import asyncio
import subprocess
from pathlib import Path
from giskard.checks import Scenario


# Path to the switch script
SCRIPT_PATH = Path(__file__).parent.parent / "scripts" / "switch_github_account.sh"


def run_switch_script(account: str = "") -> str:
    """
    Run the gh-switch script and return its output.

    Args:
        account: Account to switch to (empty string for status check)

    Returns:
        Script output as string
    """
    try:
        cmd = ["bash", str(SCRIPT_PATH)]
        if account:
            cmd.append(account)

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return "ERROR: Script timeout"
    except Exception as e:
        return f"ERROR: {str(e)}"


def get_current_gh_account() -> str:
    """Get currently authenticated gh CLI account."""
    try:
        result = subprocess.run(
            ["gh", "auth", "status"],
            capture_output=True,
            text=True,
            timeout=10
        )
        output = result.stdout + result.stderr
        # Extract username from output
        for line in output.split('\n'):
            if 'Logged in to github.com account' in line or 'as' in line:
                return output
        return output
    except Exception as e:
        return f"ERROR: {str(e)}"


async def test_status_check():
    """Test that status check works without arguments."""
    scenario = (
        Scenario("test_status_check")
        .interact(
            inputs="",
            outputs=run_switch_script,
        )
        .assert_that(
            lambda trace: "Current gh CLI account" in trace.last.outputs
            or "gh auth status" in trace.last.outputs,
            name="status output contains account info"
        )
    )

    result = await scenario.run()
    result.print_report()
    return result


async def test_switch_to_work():
    """Test switching to work account."""
    scenario = (
        Scenario("test_switch_to_work")
        .interact(
            inputs="work",
            outputs=run_switch_script,
        )
        .assert_that(
            lambda trace: "haifeng-li_sfemu" in trace.last.outputs
            or "Switched to" in trace.last.outputs
            or "ERROR" not in trace.last.outputs,
            name="switch to work account succeeds"
        )
    )

    result = await scenario.run()
    result.print_report()
    return result


async def test_switch_to_personal():
    """Test switching to personal account."""
    scenario = (
        Scenario("test_switch_to_personal")
        .interact(
            inputs="personal",
            outputs=run_switch_script,
        )
        .assert_that(
            lambda trace: "haifeng-li-at-salesforce" in trace.last.outputs
            or "Switched to" in trace.last.outputs
            or "ERROR" not in trace.last.outputs,
            name="switch to personal account succeeds"
        )
    )

    result = await scenario.run()
    result.print_report()
    return result


async def test_invalid_account():
    """Test handling of invalid account name."""
    scenario = (
        Scenario("test_invalid_account")
        .interact(
            inputs="invalid_account_name",
            outputs=run_switch_script,
        )
        .assert_that(
            lambda trace: "Invalid" in trace.last.outputs
            or "Unknown" in trace.last.outputs
            or "error" in trace.last.outputs.lower(),
            name="invalid account is rejected"
        )
    )

    result = await scenario.run()
    result.print_report()
    return result


async def test_account_persistence():
    """Test that account switch persists."""
    # Switch to work
    scenario1 = (
        Scenario("test_persistence_switch")
        .interact(inputs="work", outputs=run_switch_script)
    )
    await scenario1.run()

    # Check status after switch
    scenario2 = (
        Scenario("test_persistence_check")
        .interact(inputs="", outputs=run_switch_script)
        .assert_that(
            lambda trace: "haifeng-li_sfemu" in trace.last.outputs,
            name="work account persists after switch"
        )
    )

    result = await scenario2.run()
    result.print_report()
    return result


async def run_all_tests():
    """Run all test scenarios."""
    print("=" * 60)
    print("Running Giskard OSS Tests for gh-switch skill")
    print("=" * 60)

    tests = [
        ("Status Check", test_status_check),
        ("Switch to Work", test_switch_to_work),
        ("Switch to Personal", test_switch_to_personal),
        ("Invalid Account", test_invalid_account),
        ("Account Persistence", test_account_persistence),
    ]

    results = []
    for name, test_func in tests:
        print(f"\n{'='*60}")
        print(f"Test: {name}")
        print("="*60)
        try:
            result = await test_func()
            results.append((name, result))
        except Exception as e:
            print(f"❌ Test failed with exception: {e}")
            results.append((name, None))

    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    passed = sum(1 for _, r in results if r and r.passed)
    total = len(results)
    print(f"Passed: {passed}/{total}")

    return results


if __name__ == "__main__":
    asyncio.run(run_all_tests())
