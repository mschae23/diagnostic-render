const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("diagnostic-render", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zg = b.dependency("zg", .{});
    const bufstream = b.dependency("bufstream", .{
        .target = target,
        .optimize = optimize,
    });

    lib.addImport("zg-codepoint", zg.module("code_point"));
    lib.addImport("zg-grapheme", zg.module("grapheme"));
    lib.addImport("zg-displaywidth", zg.module("DisplayWidth"));
    lib.addImport("bufstream", bufstream.module("bufstream"));

    // b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addImport("zg-codepoint", zg.module("code_point"));
    main_tests.root_module.addImport("zg-grapheme", zg.module("grapheme"));
    main_tests.root_module.addImport("zg-displaywidth", zg.module("DisplayWidth"));
    main_tests.root_module.addImport("bufstream", bufstream.module("bufstream"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    const dev_example_exe = b.addExecutable(.{
        .name = "diagnosticrender-dev",
        .root_source_file = b.path(b.fmt("examples/dev/main.zig", .{})),
        .target = target,
        .optimize = optimize,
    });
    dev_example_exe.root_module.addImport("diagnostic-render", lib);

    const dev_example_run_cmd = b.addRunArtifact(dev_example_exe);
    if (b.args) |args| dev_example_run_cmd.addArgs(args);

    const dev_example_install_artifact = b.addInstallArtifact(dev_example_exe, .{});
    dev_example_run_cmd.step.dependOn(&dev_example_install_artifact.step);

    const run_dev_step = b.step("dev", "Run dev example");
    run_dev_step.dependOn(&dev_example_run_cmd.step);
}
