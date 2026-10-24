"""Append real process evidence to a run directory. No shell interpolation."""
import argparse,subprocess,json,datetime,platform,hashlib,time,os
from pathlib import Path

def capture(command,out,inputs=(),outputs=(),timeout=120,cwd=None):
 root=Path(__file__).resolve().parents[1];cwd=Path(cwd or root);out=Path(out);out.mkdir(parents=True,exist_ok=True)
 def git(*args):return subprocess.run(['git',*args],cwd=root,capture_output=True,text=True).stdout.strip()
 runfile=out/'run.json';run=json.loads(runfile.read_text())if runfile.exists()else{'records':[]}
 stamp=datetime.datetime.now(datetime.timezone.utc).isoformat();start=time.perf_counter()
 env=dict(os.environ);env.pop('_',None)
 try:r=subprocess.run(command,cwd=cwd,env=env,capture_output=True,text=True,timeout=timeout);code=r.returncode;stdout=r.stdout;stderr=r.stderr
 except subprocess.TimeoutExpired as e:code=124;stdout=(e.stdout or b'').decode(errors='replace')if isinstance(e.stdout,bytes)else(e.stdout or'');stderr='TIMEOUT '+str(timeout)+' seconds'
 index=len(run['records']);(out/f'{index:03}-stdout.log').write_text(stdout);(out/f'{index:03}-stderr.log').write_text(stderr)
 def hashes(paths):return {str(p):{'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest(),'size_bytes':Path(p).stat().st_size}for p in paths if Path(p).is_file()}
 entry={'utc':stamp,'command':command,'cwd':str(cwd.relative_to(root))if cwd.is_relative_to(root)else'<external-consumer>','exit_code':code,'seconds':time.perf_counter()-start,'branch':git('branch','--show-current'),'sha':git('rev-parse','HEAD'),'dirty':bool(git('status','--porcelain')),'diff_summary':git('diff','--stat'),'status_porcelain':git('status','--porcelain'),'platform':platform.platform(),'stdout':f'{index:03}-stdout.log','stderr':f'{index:03}-stderr.log','inputs':hashes(inputs),'outputs':hashes(outputs)}
 run['records'].append(entry);runfile.write_text(json.dumps(run,ensure_ascii=False,indent=2)+'\n');return code,stdout,stderr
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('command',nargs=argparse.REMAINDER);a=p.parse_args();command=a.command[1:]if a.command and a.command[0]=='--'else a.command;code,stdout,stderr=capture(command,a.output);print(stdout,end='');print(stderr,end='',file=__import__('sys').stderr);raise SystemExit(code)
