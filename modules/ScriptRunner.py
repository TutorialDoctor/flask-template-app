import subprocess



class ScriptRunner:
    @classmethod
    def run(cls,file_to_run="print.sh"):
        # Runs the script and waits for it to complete
        result = subprocess.run(["bash",f"./scripts/{file_to_run}"], capture_output=True, text=True)
        # Print the output and errors
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        print("Exit Code:", result.returncode)
        return result.stdout

        
