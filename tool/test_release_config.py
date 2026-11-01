import os,subprocess,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class ReleaseConfiguration(unittest.TestCase):
 def run_build(self,**config):
  env=os.environ.copy()
  for k in ['PRIVACY_OPERATOR','PRIVACY_CONTACT','PRIVACY_POLICY_URL','ACCOUNT_DELETION_URL']:env.pop(k,None)
  env.update(config)
  return subprocess.run(['bash','tool/build_store_bundle.sh'],cwd=ROOT,env=env,capture_output=True,text=True)
 def test_missing_policy_url_stops_before_build(self):
  r=self.run_build(PRIVACY_POLICY_URL="");self.assertNotEqual(r.returncode,0);self.assertIn('PRIVACY_POLICY_URL',r.stderr)
 def test_http_policy_rejected(self):
  r=self.run_build(PRIVACY_OPERATOR='Test',PRIVACY_CONTACT='verified elsewhere',PRIVACY_POLICY_URL='http://policy.invalid',ACCOUNT_DELETION_URL='https://delete.invalid')
  self.assertNotEqual(r.returncode,0);self.assertIn('HTTPS',r.stderr)
 def test_test_adverts_cannot_reach_production(self):
  r=self.run_build(PRIVACY_OPERATOR='Test',PRIVACY_CONTACT='Test',PRIVACY_POLICY_URL='https://policy.test',ACCOUNT_DELETION_URL='https://delete.test',ADMOB_TEST_ADS='true')
  self.assertNotEqual(r.returncode,0);self.assertIn('test advertisements',r.stderr)
if __name__=='__main__':unittest.main()
