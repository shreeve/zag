//! Zag Build Configuration

const std = @import("std");

const version = "0.1.0";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // =========================================================================
    // Parser generation step
    // =========================================================================
    //
    // Runs nexus to generate src/parser.zig from zag.grammar.
    // Requires nexus to be built: (cd ../nexus && zig build)
    //
    // Usage:
    //   zig build parser           — generate parser from grammar

    const parser_step = b.step("parser", "Generate parser from zag.grammar");
    const gen_cmd = b.addSystemCommand(&.{
        "../nexus/bin/nexus",
        "zag.grammar",
        "src/parser.zig",
    });
    parser_step.dependOn(&gen_cmd.step);

    // =========================================================================
    // Main executable — zag compiler driver
    // =========================================================================

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zag",
        .root_module = main_mod,
    });

    const install_exe = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = ".." } },
        .dest_sub_path = "bin/zag",
    });
    b.getInstallStep().dependOn(&install_exe.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the Zag compiler");
    run_step.dependOn(&run_cmd.step);

    // =========================================================================
    // Tests
    // =========================================================================

    const test_step = b.step("test", "Run tests");

    const zag_test_mod = b.createModule(.{
        .root_source_file = b.path("src/zag.zig"),
        .target = target,
        .optimize = optimize,
    });
    const zag_tests = b.addTest(.{ .root_module = zag_test_mod });
    const run_zag_tests = b.addRunArtifact(zag_tests);
    test_step.dependOn(&run_zag_tests.step);
}
