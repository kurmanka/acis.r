package Web::App;

sub noop {};

*log_profiling   = \&noop;
*time_checkpoint = \&noop;
*report_timed_checkpoints = \&noop;

1;

