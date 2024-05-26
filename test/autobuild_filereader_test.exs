defmodule Autobuild.FilereaderTest do
  use ExUnit.Case

  test "it can parse a stream and return lines of code" do
    # Create file
    source = """
    import os
    import sys
    import time

    def hello():
        return "World"

    def goodbye():
        return "Goodbye"

    """

    File.write!("example.py", source, [:write, :binary])

    result = Autobuild.Filereader.read_file("example.py", "testing")

    assert result ==
             {:ok, "example.py", ["import os\n", "import sys\n", "import time\n"],
              [
                "\n",
                "def hello():\n",
                "    return \"World\"\n",
                "\n",
                "def goodbye():\n",
                "    return \"Goodbye\"\n",
                "\n"
              ], "testing"}

    File.rm!("example.py")
  end
end
