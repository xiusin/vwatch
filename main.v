module main

import os
import cli
import serkonda7.termtable as tt
import v.util.version
import vwatch
import xiusin.vcolor

fn main() {
	cfg := $embed_file('vwatch.toml', .zlib)
	mut app := cli.Command{
		name: 'vwatch'
		description: 'A hot-reloading tool developed with V Language.'
		execute: fn (cmd cli.Command) ! {
			println(cmd.help_message())
			return
		}
		commands: [
			cli.Command{
				name: 'init'
				description: 'Generate configuration file.'
				execute: fn [cfg] (cmd cli.Command) ! {
					os.write_file('vwatch.toml', cfg.to_string())!
					println('${vcolor.green_string('vwatch.toml')} has generated.')
				}
			},
			cli.Command{
				name: 'update'
				description: 'Update vwatch.'
				execute: fn (cmd cli.Command) ! {
					vwatch.update_vwatch()!
				}
			},
			cli.Command{
				name: 'run'
				flags: [
					cli.Flag{
						flag: .string
						name: 'c'
						description: 'set config file path.'
						default_value: ['vwatch.toml']
					},
				]
				description: 'Run the application by starting a local development server.'
				execute: fn (_ cli.Command) ! {
					vwatch.watch_run()!
				}
			},
			cli.Command{
				name: 'server'
				flags: [
					cli.Flag{
						flag: .int
						name: 'port'
						description: 'set server port.'
					},
					cli.Flag{
						flag: .string
						name: 'domain'
						description: 'proxy domain.'
					},
				]
				description: 'Serving static content over HTTP on port.'
				execute: fn (cmd cli.Command) ! {
					port := cmd.flags.get_int('port')!
					proxy_domain := cmd.flags.get_string('domain')!
					if proxy_domain.len > 0 && !proxy_domain.starts_with('http') {
						panic(error('domain has starts with `http`'))
					}
					vwatch.server(if port > 0 { port } else { 8080 }, proxy_domain)!
				}
			},
			cli.Command{
				name: 'version'
				description: 'Print the vwatch version.'
				execute: fn (_ cli.Command) ! {
					data := [
						['Name', 'Version', 'Description'],
						['V', version.v_version + '-' + version.vhash(), 'The V language version'],
						['VWatch', vwatch.vwatch_version, 'The vwatch version'],
						['Os', os.user_os(), 'Name of the operating system (OS)'],
					]
					t := tt.Table{
						data: data
						style: .simple
						header_style: .bold
						align: .left
						orientation: .row
						padding: 1
						tabsize: 4
					}
					println(t)
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
