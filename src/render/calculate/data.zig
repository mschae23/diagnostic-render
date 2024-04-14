const std = @import("std");
const diag = @import("../../diagnostic.zig");
const Diagnostic = diag.Diagnostic;
const Annotation = diag.Annotation;
const AnnotationStyle = diag.AnnotationStyle;
const Severity = diag.Severity;
const LineColumn = @import("../../file.zig").LineColumn;

/// Data for a continuing multi-line annotation. This is an annotation that starts
/// on a line before the currently rendered one, and ends after it.
///
/// This is drawn as a single `|` character to the left of the source code.
pub const ContinuingMultilineAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    /// The index of this continuing vertical bar.
    vertical_bar_index: usize,
};

/// Data for a connecting multi-line annotation. This is an annotation that is
/// running from the continuing vertical bars on the left over to its
/// location in the source code on this line.
///
/// This is used for both annotations starting or ending on a line.
/// It can only occur once per line (but of course, multiple times per source line).
///
/// This is drawn as underscores from the vertical bars to `end_location` (exclusive).
pub const ConnectingMultilineAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    end_location: LineColumn,
    /// The index of the continuing vertical bar on the left this annotation connects with.
    vertical_bar_index: usize,
};

/// Data for a starting annotation. That is an annotation,
/// either single-line or multi-line, which starts on this line.
///
/// This is drawn as a single boundary character at `location`.
/// This can occur multiple times per line.
pub const StartAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    location: LineColumn,
};

/// Data for a connecting single-line annotation. This is an annotation that is
/// entirely on a single line. This data represents the underline showing where
/// that annotation starts and ends.
///
/// This is drawn as underline characters (or underscores if `as_multiline` is `true`)
/// running from `start_column_index` (inclusive) to `end_column_index` (exclusive).
/// This can occur multiple times per line.
pub const ConnectingSinglelineAnnotationData = struct {
    style: AnnotationStyle, as_multiline: bool,
    severity: Severity,
    line_index: usize,
    start_column_index: usize, end_column_index: usize,
};

/// Data for an ending annotation. That is an annotation,
/// either single-line or multi-line, which ends on this line.
///
/// This is drawn as a single boundary character at `location`.
/// This can occur multiple times per line.
pub const EndAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    location: LineColumn,
};

/// Data for a hanging label. This is for annotations where their
/// label would intersect with other annotations after them,
/// so they are displayed below their [`StartAnnotationData`].
///
/// This is drawn as a single `|` character at `location`.
/// This can occur multiple times per line.
///
/// [`StartAnnotationData`]: StartAnnotationData
pub const HangingAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    location: LineColumn,
};

/// Data for a label.
///
/// When after an [`EndAnnotationData`], `location` is ignored, as
/// it is the end of the line anyway. Otherwise, it is a hanging label,
/// which uses `location` for the column to print it at.
///
/// This is drawn as a label, of course, so it will simply print `label`
/// at the end of the line or at `location`.
/// This can only occur once per line.
///
/// [`EndAnnotationData`]: EndAnnotationData
pub const LabelAnnotationData = struct {
    style: AnnotationStyle,
    severity: Severity,
    location: LineColumn,
    label: []const u8,
};

/// A combination of [`StartAnnotationData`] and [`EndAnnotationData`].
///
/// This is drawn as two single boundary characters at their respective
/// `location`s. This can occur multiple times per line.
///
/// [`StartAnnotationData`]: StartAnnotationData
/// [`EndAnnotationData`]: EndAnnotationData
pub const BothAnnotationData = struct {
    start: StartAnnotationData,
    end: EndAnnotationData,
};

/// An enum with variants for [`StartAnnotationData`] and
/// [`EndAnnotationData`], respectively.
///
/// [`StartAnnotationData`]: StartAnnotationData
/// [`EndAnnotationData`]: EndAnnotationData
pub const StartEndAnnotationData = union(enum) {
    start: StartAnnotationData,
    end: EndAnnotationData,
    both: BothAnnotationData,
};

/// A tagged union for the different types of annotation data.
pub const AnnotationData = union(enum) {
    continuing_multiline: ContinuingMultilineAnnotationData,
    connecting_multiline: ConnectingMultilineAnnotationData,
    start: StartAnnotationData,
    connecting_singleline: ConnectingSinglelineAnnotationData,
    end: EndAnnotationData,
    hanging: HangingAnnotationData,
    label: LabelAnnotationData,
};

