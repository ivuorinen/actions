#!/usr/bin/env python3
"""Performance benchmarking tool for validators.

Measures validation performance and identifies bottlenecks.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import statistics
import sys
import time
from typing import Any

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.registry import ValidatorRegistry


class ValidatorBenchmark:
    """Benchmark utility for validators."""

    def __init__(self, iterations: int = 100) -> None:
        """Initialize the benchmark tool.

        Args:
            iterations: Number of iterations for each test
        """
        self.iterations = iterations
        self.registry = ValidatorRegistry()
        self.results: dict[str, list[float]] = {}

    def benchmark_action(
        self,
        action_type: str,
        inputs: dict[str, str],
        iterations: int | None = None,
    ) -> dict[str, Any]:
        """Benchmark validation for an action.

        Args:
            action_type: The action type to validate
            inputs: Dictionary of inputs to validate
            iterations: Number of iterations (overrides default)

        Returns:
            Benchmark results dictionary
        """
        iterations = iterations or self.iterations
        times = []

        # Get the validator once (to exclude loading time)
        validator = self.registry.get_validator(action_type)

        print(f"\nBenchmarking {action_type} with {len(inputs)} inputs...")
        print(f"Running {iterations} iterations...")

        # Warm-up run
        validator.clear_errors()
        result = validator.validate_inputs(inputs)

        # Benchmark runs
        for i in range(iterations):
            validator.clear_errors()

            start = time.perf_counter()
            result = validator.validate_inputs(inputs)
            end = time.perf_counter()

            times.append(end - start)

            if (i + 1) % 10 == 0:
                print(f"  Progress: {i + 1}/{iterations}", end="\r")

        print(f"  Completed: {iterations}/{iterations}")

        # Calculate statistics
        stats = self._calculate_stats(times)
        stats["action_type"] = action_type
        stats["validator"] = validator.__class__.__name__
        stats["input_count"] = len(inputs)
        stats["iterations"] = iterations
        stats["validation_result"] = result
        stats["errors"] = len(validator.errors)

        return stats

    def _calculate_stats(self, times: list[float]) -> dict[str, Any]:
        """Calculate statistics from timing data.

        Args:
            times: List of execution times

        Returns:
            Statistics dictionary
        """
        times_ms = [t * 1000 for t in times]  # Convert to milliseconds

        return {
            "min_ms": min(times_ms),
            "max_ms": max(times_ms),
            "mean_ms": statistics.mean(times_ms),
            "median_ms": statistics.median(times_ms),
            "stdev_ms": statistics.stdev(times_ms) if len(times_ms) > 1 else 0,
            "total_s": sum(times),
            "per_second": len(times) / sum(times) if sum(times) > 0 else 0,
        }

    def compare_validators(self, test_cases: list[dict[str, Any]]) -> None:
        """Compare performance across multiple validators.

        Args:
            test_cases: List of test cases with action_type and inputs
        """
        results = []

        print("\n" + "=" * 70)
        print("Validator Performance Comparison")
        print("=" * 70)

        for case in test_cases:
            stats = self.benchmark_action(case["action_type"], case["inputs"])
            results.append(stats)

        # Display comparison table
        self._display_comparison(results)

    def _display_comparison(self, results: list[dict[str, Any]]) -> None:
        """Display comparison table of benchmark results.

        Args:
            results: List of benchmark results
        """
        print("\nResults Summary:")
        print("-" * 70)
        print(
            f"{'Action':<20} {'Validator':<20} {'Inputs':<8} {'Mean (ms)':<12} {'Ops/sec':<10}",
        )
        print("-" * 70)

        for r in results:
            print(
                f"{r['action_type']:<20} "
                f"{r['validator']:<20} "
                f"{r['input_count']:<8} "
                f"{r['mean_ms']:<12.3f} "
                f"{r['per_second']:<10.1f}",
            )

        print("\nDetailed Statistics:")
        print("-" * 70)
        for r in results:
            print(f"\n{r['action_type']} ({r['validator']}):")
            print(f"  Min:    {r['min_ms']:.3f} ms")
            print(f"  Max:    {r['max_ms']:.3f} ms")
            print(f"  Mean:   {r['mean_ms']:.3f} ms")
            print(f"  Median: {r['median_ms']:.3f} ms")
            print(f"  StdDev: {r['stdev_ms']:.3f} ms")
            print(f"  Validation Result: {'PASS' if r['validation_result'] else 'FAIL'}")
            if r["errors"] > 0:
                print(f"  Errors: {r['errors']}")

    def profile_validator(self, action_type: str, inputs: dict[str, str]) -> None:
        """Profile a validator to identify bottlenecks.

        Args:
            action_type: The action type to validate
            inputs: Dictionary of inputs to validate
        """
        import cProfile
        from io import StringIO
        import pstats

        print(f"\nProfiling {action_type} validator...")
        print("-" * 70)

        validator = self.registry.get_validator(action_type)

        # Create profiler
        profiler = cProfile.Profile()

        # Profile the validation
        profiler.enable()
        for _ in range(10):  # Run multiple times for better data
            validator.clear_errors()
            validator.validate_inputs(inputs)
        profiler.disable()

        # Print statistics
        stream = StringIO()
        stats = pstats.Stats(profiler, stream=stream)
        stats.strip_dirs()
        stats.sort_stats("cumulative")
        stats.print_stats(20)  # Top 20 functions

        print(stream.getvalue())

    def benchmark_patterns(self) -> None:
        """Benchmark pattern matching for convention-based validation."""
        from validators.conventions import ConventionBasedValidator

        print("\n" + "=" * 70)
        print("Pattern Matching Performance")
        print("=" * 70)

        validator = ConventionBasedValidator("test")
        # Access the internal pattern mapping
        mapper = getattr(validator, "_convention_mapper", None)
        if not mapper:
            print("Convention mapper not available")
            return

        # Test inputs with different pattern types
        test_inputs = {
            # Exact matches
            "dry-run": "true",
            "verbose": "false",
            "debug": "true",
            # Prefix matches
            "github-token": "ghp_xxx",
            "npm-token": "xxx",
            "api-token": "xxx",
            # Suffix matches
            "node-version": "18.0.0",
            "python-version": "3.9",
            # Contains matches
            "webhook-url": "https://example.com",
            "api-url": "https://api.example.com",
            # No matches
            "custom-field-1": "value1",
            "custom-field-2": "value2",
            "custom-field-3": "value3",
        }

        times = []
        for _ in range(self.iterations):
            start = time.perf_counter()
            for name in test_inputs:
                mapper.get_validator_type(name)
            end = time.perf_counter()
            times.append(end - start)

        stats = self._calculate_stats(times)

        print(f"\nPattern matching for {len(test_inputs)} inputs:")
        print(f"  Mean:   {stats['mean_ms']:.3f} ms")
        print(f"  Median: {stats['median_ms']:.3f} ms")
        print(f"  Min:    {stats['min_ms']:.3f} ms")
        print(f"  Max:    {stats['max_ms']:.3f} ms")
        print(f"  Lookups/sec: {len(test_inputs) * self.iterations / stats['total_s']:.0f}")

    def save_results(self, results: dict[str, Any], filepath: Path) -> None:
        """Save benchmark results to file.

        Args:
            results: Benchmark results
            filepath: Path to save results
        """
        with filepath.open("w") as f:
            json.dump(results, f, indent=2)
        print(f"\nResults saved to {filepath}")


def create_test_inputs(input_count: int) -> dict[str, str]:
    """Create test inputs for benchmarking.

    Args:
        input_count: Number of inputs to create

    Returns:
        Dictionary of test inputs
    """
    inputs = {}

    # Add various input types
    patterns = [
        ("github-token", "${{ secrets.GITHUB_TOKEN }}"),
        ("node-version", "18.0.0"),
        ("python-version", "3.9.0"),
        ("dry-run", "true"),
        ("verbose", "false"),
        ("max-retries", "5"),
        ("rate-limit", "100"),
        ("config-file", "./config.yml"),
        ("output-path", "./output"),
        ("webhook-url", "https://example.com/webhook"),
        ("api-url", "https://api.example.com"),
        ("docker-image", "nginx:latest"),
        ("dockerfile", "Dockerfile"),
    ]

    for i in range(input_count):
        pattern = patterns[i % len(patterns)]
        name = f"{pattern[0]}-{i}" if i > 0 else pattern[0]
        inputs[name] = pattern[1]

    return inputs


def main() -> None:
    """Main entry point for the benchmark utility."""
    parser = argparse.ArgumentParser(
        description="Benchmark validator performance",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Benchmark specific action
  %(prog)s --action docker-build --inputs 10

  # Compare multiple validators
  %(prog)s --compare

  # Profile a validator
  %(prog)s --profile docker-build

  # Benchmark pattern matching
  %(prog)s --patterns
        """,
    )

    parser.add_argument(
        "--action",
        "-a",
        help="Action type to benchmark",
    )
    parser.add_argument(
        "--inputs",
        "-i",
        type=int,
        default=10,
        help="Number of inputs to test (default: 10)",
    )
    parser.add_argument(
        "--iterations",
        "-n",
        type=int,
        default=100,
        help="Number of iterations (default: 100)",
    )
    parser.add_argument(
        "--compare",
        "-c",
        action="store_true",
        help="Compare multiple validators",
    )
    parser.add_argument(
        "--profile",
        "-p",
        metavar="ACTION",
        help="Profile a specific validator",
    )
    parser.add_argument(
        "--patterns",
        action="store_true",
        help="Benchmark pattern matching",
    )
    parser.add_argument(
        "--save",
        "-s",
        type=Path,
        help="Save results to JSON file",
    )

    args = parser.parse_args()

    # Create benchmark tool
    benchmark = ValidatorBenchmark(iterations=args.iterations)

    if args.compare:
        # Compare different validators
        test_cases = [
            {
                "action_type": "docker-build",
                "inputs": create_test_inputs(args.inputs),
            },
            {
                "action_type": "github-release",
                "inputs": create_test_inputs(args.inputs),
            },
            {
                "action_type": "test-action",  # Uses convention-based
                "inputs": create_test_inputs(args.inputs),
            },
        ]
        benchmark.compare_validators(test_cases)

    elif args.profile:
        # Profile specific validator
        inputs = create_test_inputs(args.inputs)
        benchmark.profile_validator(args.profile, inputs)

    elif args.patterns:
        # Benchmark pattern matching
        benchmark.benchmark_patterns()

    elif args.action:
        # Benchmark specific action
        inputs = create_test_inputs(args.inputs)
        results = benchmark.benchmark_action(args.action, inputs)

        # Display results
        print("\n" + "=" * 70)
        print("Benchmark Results")
        print("=" * 70)
        print(f"Action: {results['action_type']}")
        print(f"Validator: {results['validator']}")
        print(f"Inputs: {results['input_count']}")
        print(f"Iterations: {results['iterations']}")
        print("-" * 70)
        print(f"Mean:   {results['mean_ms']:.3f} ms")
        print(f"Median: {results['median_ms']:.3f} ms")
        print(f"Min:    {results['min_ms']:.3f} ms")
        print(f"Max:    {results['max_ms']:.3f} ms")
        print(f"StdDev: {results['stdev_ms']:.3f} ms")
        print(f"Ops/sec: {results['per_second']:.1f}")

        if args.save:
            benchmark.save_results(results, args.save)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
