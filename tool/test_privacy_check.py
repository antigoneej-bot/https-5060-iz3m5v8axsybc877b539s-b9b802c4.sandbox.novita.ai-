import importlib.util
from pathlib import Path
import json,subprocess,unittest
from types import SimpleNamespace
spec=importlib.util.spec_from_file_location('privacy_check',Path(__file__).with_name('Mindnyang-Privacy-Check.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class MetadataCheck(unittest.TestCase):
 def test_no_write_or_userdata_commands(self):
  for _,args,_ in m.QUERIES:
   self.assertTrue('describe' in args or 'list' in args)
   self.assertFalse(set(args)&{'update','delete','deploy','read','access','print-access-token'})
 def test_private_fields_discarded(self):
  r=m.project_result('garden_runtime',{'state':'ACTIVE','serviceConfig':{'environmentVariables':{'RELEASE_ENV':'test','PREMIUM_TEST_ACCESS':'true','SECRET':'private-secret'}}})
  self.assertNotIn('private-secret',json.dumps(r))
  self.assertNotIn('SECRET',json.dumps(r))
 def test_error_does_not_print_raw_message(self):
  def run(*a,**kw):return SimpleNamespace(returncode=1,stdout=b'',stderr=b'token=private-secret')
  r=m.query('firestore',[], '',run)
  self.assertEqual(r['status'],'UNKNOWN');self.assertNotIn('private-secret',str(r))
 def test_missing_not_invented(self):
  self.assertEqual(m.project_result('storage',{}),{})
  self.assertEqual(m.project_result('garden_runtime',{})['PREMIUM_TEST_ACCESS'],'UNKNOWN')
 def test_ttl_filters_unrelated_data(self):
  r=m.project_result('login_session_ttl',[{'name':'projects/p/databases/(default)/collectionGroups/private-users/fields/expireAt','ttlConfig':{'state':'ACTIVE'}},{'name':'projects/p/databases/(default)/collectionGroups/socialAuthSessions/fields/expireAt','ttlConfig':{'state':'ACTIVE'}}])
  self.assertEqual(r,[{'collection':'socialAuthSessions','field':'expireAt','state':'ACTIVE'}])
 def test_timeout_unknown(self):
  def run(*a,**kw):raise subprocess.TimeoutExpired('gcloud',35)
  self.assertEqual(m.query('firestore',[],'',run)['status'],'UNKNOWN')
 def test_command_uses_fixed_project_and_no_shell(self):
  def run(args,**kw):
   self.assertIn('--project=mycatapp-99bc8',args);self.assertNotIn('shell',kw)
   return SimpleNamespace(returncode=0,stdout=b'{"locationId":"asia-northeast3"}',stderr=b'')
  self.assertEqual(m.query(*m.QUERIES[0],run=run)['metadata']['locationId'],'asia-northeast3')
if __name__=='__main__':unittest.main()
