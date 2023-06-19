module vwatch

import os
import time

struct WatchCfg {
	pub mut:
	max_file_cnt       i64
	watch_extensions   []string
	build_on_change    []string
	ignores_pattern    string
	build_bin_name     string
	exec_template      string
	watch_dir          string
	git_pull           bool
	git_pull_tick_time time.Duration
	print_startup_info bool
}

fn (mut cfg WatchCfg) check() {
	if cfg.build_on_change.len == 0 {
		cfg.build_on_change = ['go', 'build', '-o']
		cfg.build_on_change[0] = os.find_abs_path_of_executable(cfg.build_on_change[0]) or {
			panic(err)
		}

	}
	cfg.build_on_change = cfg.build_on_change.map(it.replace("\${pwd}", os.abs_path('.')))

	if cfg.watch_extensions.len == 0 {
		cfg.watch_extensions = ['.go', '.v', '.toml', '.yaml']
	}
	if cfg.watch_dir.len == 0 {
		cfg.watch_dir = os.abs_path('.')
	}

	if cfg.max_file_cnt == 0 {
		cfg.max_file_cnt = 300
	}

	if cfg.git_pull_tick_time == 0 {
		cfg.git_pull_tick_time = 5
	}

	if cfg.build_bin_name.len == 0 {
		cfg.build_bin_name = os.base(os.abs_path('.'))
	}
	$if windows {
		cfg.build_bin_name += '.exe'
	}
}
