package 'ldbt'
version '0.0.1'
description 'luna dial\'s build tool'
author 'luna dial system'

target '5.1'
compat 'optional'

dependencies {
    lua :version '>=5.1',
    rock 'tl' :version '>=0.24.8-1',

    rock 'argparse' :version '>=0.7.1-1',
    rock 'ansicolors' :version '>=1.0.2-3',
    rock 'semver' :version '>=1.2.1-1',
    rock 'luafilesystem' :version '>=1.9.0-1',

    rock 'argparse-tl-type' :version '>=0.0.1-1',
    rock 'ansicolors-tl-type' :version '>=0.0.1-1',
    rock 'luafilesystem-tl-type' :version '>=0.0.1-1',
}