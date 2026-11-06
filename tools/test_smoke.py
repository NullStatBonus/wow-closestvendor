import unittest


class Smoke(unittest.TestCase):
    def test_runs(self):
        self.assertEqual(1 + 1, 2)


if __name__ == "__main__":
    unittest.main()
