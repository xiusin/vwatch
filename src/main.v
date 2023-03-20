module main

import os
import cli
import serkonda7.termtable as tt
import v.util.version
import vweb
import term
import vwatch

const vwatch_version = "v0.1.0-alpha"

struct App {
	vweb.Context
}

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
					os.write_file("vwatch.toml", cfg.to_string())!
					println('${term.green('vwatch.toml')} has generated.')
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
					vwatch.watch_run()
				}
			},
				cli.Command{
				name: 'server'
				description: 'Serving static content over HTTP on port.'
				execute: fn (_ cli.Command) ! {
					mut app := &App{}
					os.chdir(os.dir(os.executable()))!
					app.handle_static("./", true)
					vweb.run(app, 8081)
				}
			},
				cli.Command{
				name: 'version'
				description: 'Print the vwatch version.'
				execute: fn (_ cli.Command) ! {
					data := [
						['Name', 'Version', 'Description'],
						['V', version.v_version + '-' + version.vhash(), 'The V language version'],
						['VWatch',vwatch_version, 'The vwatch version'],
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
