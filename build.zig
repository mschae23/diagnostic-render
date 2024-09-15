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

    lib.addImport("zg-codepoint", zg.module("code_point"));
    lib.addImport("zg-grapheme", zg.module("grapheme"));
    lib.addImport("zg-displaywidth", zg.module("DisplayWidth"));

    // b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addImport("zg-codepoint", zg.module("code_point"));
    main_tests.root_module.addImport("zg-grapheme", zg.module("grapheme"));
    main_tests.root_module.addImport("zg-displaywidth", zg.module("DisplayWidth"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
