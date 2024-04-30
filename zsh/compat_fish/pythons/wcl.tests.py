import unittest
from wcl import parse_repo, relative_repo_dir, clone_url


class TestParseGeneral(unittest.TestCase):

    def test_https_dotgit_suffix(self):
        # .git suffix shown in the various "clone" popups (confirmed: github,bitbucket,gitlab)
        parsed = parse_repo('https://gitlab.com/g0t4/dotfiles.git')
        self.assertEqual(parsed.domain, 'gitlab.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_space_padding_ignores(self):
        parsed = parse_repo('  https://gitlab.com/g0t4/dotfiles.git  ')
        self.assertEqual(parsed.domain, 'gitlab.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')


class TestMapToRepoDir(unittest.TestCase):

    def test_github(self):
        repo_dir = relative_repo_dir(
            parse_repo('git@github.com:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_bitbucket(self):
        repo_dir = relative_repo_dir(
            parse_repo('git@bitbucket.org:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'bitbucket/g0t4/dotfiles')

    def test_gitlab(self):
        repo_dir = relative_repo_dir(
            parse_repo('git@gitlab.com:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'gitlab/g0t4/dotfiles')

    def test_repo_only(self):
        repo_dir = relative_repo_dir(parse_repo('dotfiles'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_org_repo_only(self):
        repo_dir = relative_repo_dir(parse_repo('g0t4/dotfiles'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_sourceware_org(self):
        repo_dir = relative_repo_dir(
            parse_repo('https://sourceware.org/git/glibc.git'))
        self.assertEqual(repo_dir, 'sourceware.org/git/glibc')


class TestNormalizedCloneUrl(unittest.TestCase):

    def test_git_uses_git(self):
        url = clone_url(parse_repo('git@github.com:g0t4/dotfiles.git'))
        self.assertEqual(url, 'git@github.com:g0t4/dotfiles')  # drop .git

    def test_https_uses_git(self):
        url = clone_url(parse_repo('https://github.com/g0t4/dotfiles.git'))
        self.assertEqual(url, 'git@github.com:g0t4/dotfiles')  # drop .git

class TestParseThirdParty(unittest.TestCase):

    def test_sourceware_org_urls(self):
        parsed = parse_repo('https://sourceware.org/git/glibc.git')
        self.assertEqual(parsed.domain, 'sourceware.org')
        self.assertEqual(parsed.owner, 'git')
        self.assertEqual(parsed.repo, 'glibc')

class TestParseGitHub(unittest.TestCase):

    def test_github_urls(self):
        parsed = parse_repo('git@github.com:g0t4/dotfiles.git')
        self.assertEqual(parsed.domain, 'github.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_github_https(self):
        parsed = parse_repo('https://github.com/g0t4/dotfiles')
        self.assertEqual(parsed.domain, 'github.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_https_includes_branch_and_path(self):
        # this use case is NICE-TO-HAVE and not mission critical
        # - I rarely use a file link to trigger a clone
        # - if it gets too complicated, remove it

        parsed = parse_repo(
            'https://github.com/g0t4/dotfiles/blob/master/git/linux.gitconfig')
        self.assertEqual(parsed.domain, 'github.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    # PRN map githubusercontent.com => github
    # def test_map_githubusercontent_to_github(self):
    #     parsed = parse_repo(
    #         'https://raw.githubusercontent.com/g0t4/dotfiles/master/git/linux.gitconfig')
    #     self.assertEqual(parsed.domain, 'github.com')
    #     self.assertEqual(parsed.owner, 'g0t4')
    #     self.assertEqual(parsed.repo, 'dotfiles')


class TestParseBitbucket(unittest.TestCase):

    def test_bitbucket_https(self):
        parsed = parse_repo('https://bitbucket.org/g0t4/dotfiles')
        self.assertEqual(parsed.domain, 'bitbucket.org')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_bitbucket_ssh(self):
        parsed = parse_repo('git@bitbucket.org:g0t4/dotfiles.git')
        self.assertEqual(parsed.domain, 'bitbucket.org')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')


class TestParseGitLab(unittest.TestCase):

    def test_gitlab_https(self):
        parsed = parse_repo('https://gitlab.com/g0t4/dotfiles')
        self.assertEqual(parsed.domain, 'gitlab.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_gitlab_ssh(self):
        parsed = parse_repo('git@gitlab.com:g0t4/dotfiles.git')
        self.assertEqual(parsed.domain, 'gitlab.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')


class TestDefaultToGitHub(unittest.TestCase):

    def test_repoOnly_assumes_github_g0t4(self):
        parsed = parse_repo('dotfiles')
        self.assertEqual(parsed.domain, 'github.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')

    def test_orgRepoOnly_assumes_github(self):
        parsed = parse_repo('g0t4/dotfiles')
        self.assertEqual(parsed.domain, 'github.com')
        self.assertEqual(parsed.owner, 'g0t4')
        self.assertEqual(parsed.repo, 'dotfiles')


class TestParseHuggingFace(unittest.TestCase):

    # IIRC hf.co / huggingface.co are interchangeable (though huggingface.co website shows https+huggingface.co and git+hf.co only)
    # git@hf.co:microsoft/speecht5_tts
    # https://huggingface.co/microsoft/speecht5_tts
    #   PRN https+hf.co?
    #   PRN git@huggingface.co?

    def test_huggingface(self):
        parsed = parse_repo('https://huggingface.co/microsoft/speecht5_tts')
        self.assertEqual(parsed.domain, 'huggingface.co')
        self.assertEqual(parsed.owner, 'microsoft')
        self.assertEqual(parsed.repo, 'speecht5_tts')


# TODO support hg (mercurial)?
#  hg.nginx.org/nginx
#  hg.nginx.org/nginx.org

if __name__ == '__main__':
    unittest.main()
