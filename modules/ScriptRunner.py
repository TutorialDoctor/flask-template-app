import subprocess

class ScriptRunner:
    @classmethod
    def run_bash(cls,file_to_run="print.sh"):
        result = subprocess.run(["bash",f"./scripts/{file_to_run}"], capture_output=True, text=True)
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        print("Exit Code:", result.returncode)
        return result.stdout

    @classmethod
    def run_python(cls,file_to_run="test.py"):
        result = subprocess.run(["python3",f"./scripts/{file_to_run}"], capture_output=True, text=True)
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        print("Exit Code:", result.returncode)
        return result.stdout
    