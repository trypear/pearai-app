/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

'use strict';

// Increase max listeners for event emitters
require('events').EventEmitter.defaultMaxListeners = 100;

const gulp = require('gulp');
const util = require('./lib/util');
const task = require('./lib/task');
const processIfModified = require('gulp-process-if-modified');
const newer = require('gulp-newer');
const os = require('os');
const path = require('path');
const { transpileClientSWC, transpileTask, compileTask, watchTask, compileApiProposalNamesTask, watchApiProposalNamesTask } = require('./lib/compilation');
const { monacoTypecheckTask/* , monacoTypecheckWatchTask */ } = require('./gulpfile.editor');
const { compileExtensionsTask, watchExtensionsTask, compileExtensionMediaTask } = require('./gulpfile.extensions');

// API proposal names
gulp.task(compileApiProposalNamesTask);
gulp.task(watchApiProposalNamesTask);

// SWC Client Transpile
const transpileClientSWCTask = task.define('transpile-client-esbuild', task.series(util.rimraf('out'), transpileTask('src', 'out', true)));
gulp.task(transpileClientSWCTask);

// Transpile only
const transpileClientTask = task.define('transpile-client', task.series(util.rimraf('out'), transpileTask('src', 'out')));
gulp.task(transpileClientTask);

// Fast compile for development time
const compileClientTask = task.define('compile-client', task.series(util.rimraf('out'), compileApiProposalNamesTask, compileTask('src', 'out', false)));
gulp.task(compileClientTask);

const watchClientTask = task.define('watch-client', task.series(util.rimraf('out'), task.parallel(watchTask('out', false), watchApiProposalNamesTask)));
gulp.task(watchClientTask);

// Configure TypeScript compilation options for faster builds
const tsOptions = {
	incremental: true,
	tsBuildInfoFile: '.gulp-tsbuildinfo',
	skipLibCheck: true, // Skip type checking of declaration files
	isolatedModules: true, // Faster compilation, treats each file as a separate module
	noEmit: false,
	sourceMap: true,
	maxNodeModuleJsDepth: 0, // Don't type check node_modules
	typescript: require('typescript'), // Use local typescript installation
	// Use maximum number of CPU cores for compilation
	workers: Math.max(os.cpus().length - 1, 1)
};

// Optimized Linux x64 build configuration
const linuxX64Options = {
	...tsOptions,
	skipLibCheck: true,
	isolatedModules: true,
	noEmit: false,
	incremental: true,
	target: 'es2020',
	module: 'commonjs',
	moduleResolution: 'node',
	workers: os.cpus().length, // Use all CPU cores
	types: ['node'],
	lib: ['es2020'],
	outDir: path.join('out', 'linux-x64'),
};

// Modify compile task to use caching and parallel execution
const _compileTask = task.define('compile', task.series(
	util.rimraf('out'),
	task.parallel(
		monacoTypecheckTask,
		() => {
			const sources = [
				'src/**/*.ts',
				'src/**/*.tsx',
				'typings/**/*.ts',
				'tsconfig.json'
			];

			return gulp.src(sources, { buffer: false }) // Use streaming mode
				.pipe(newer({ // Only pass through newer files
					dest: 'out',
					ext: '.js' // Compare against JS files
				}))
				.pipe(processIfModified())
				.pipe(sourcemaps.init())
				.pipe(tsProject(tsOptions))
				.pipe(sourcemaps.write('.'))
				.pipe(gulp.dest('out'));
		},
		compileExtensionsTask,
		compileExtensionMediaTask
	)
));

// Add a faster compile task for development
const fastCompileTask = task.define('fast-compile', () => {
	const sources = [
		'src/**/*.ts',
		'src/**/*.tsx'
	];

	return gulp.src(sources, { buffer: false })
		.pipe(newer({
			dest: 'out',
			ext: '.js'
		}))
		.pipe(processIfModified())
		.pipe(sourcemaps.init())
		.pipe(tsProject({
			...tsOptions,
			isolatedModules: true,
			skipLibCheck: true,
			noEmit: false,
			incremental: true
		}))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('out'));
});

gulp.task('fast', fastCompileTask);

// Fast Linux x64 specific build task
const fastLinuxBuildTask = task.define('fast-linux', () => {
	const sources = [
		'src/**/*.ts',
		'src/**/*.tsx'
	];

	return gulp.src(sources, { buffer: false })
		.pipe(newer({
			dest: 'out/linux-x64',
			ext: '.js'
		}))
		.pipe(processIfModified())
		.pipe(sourcemaps.init())
		.pipe(tsProject(linuxX64Options))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('out/linux-x64'));
});

gulp.task('linux-x64', fastLinuxBuildTask);

gulp.task(task.define('watch', task.parallel(/* monacoTypecheckWatchTask, */ watchClientTask, watchExtensionsTask)));

// Default
gulp.task('default', _compileTask);

process.on('unhandledRejection', (reason, p) => {
	console.log('Unhandled Rejection at: Promise', p, 'reason:', reason);
	process.exit(1);
});

// Load all the gulpfiles only if running tasks other than the editor tasks
require('glob').sync('gulpfile.*.js', { cwd: __dirname })
	.forEach(f => require(`./${f}`));
