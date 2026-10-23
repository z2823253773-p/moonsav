#!/usr/bin/env node
import {main} from '../node/cli.mjs';
process.exitCode=await main();
