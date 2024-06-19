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

  test "it ignores files that begin with an underscore" do
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

    File.write!("_example.py", source, [:write, :binary])

    result =
      Autobuild.Filereader.read_file(
        "_example.py",
        "testing"
      )

    assert result == {
             :error,
             "File is protected: _example.py"
           }

    File.rm!("_example.py")
  end

  test "it returns an error if the file does not exist" do
    result =
      Autobuild.Filereader.read_file(
        "non_existent_file.py",
        "testing"
      )

    assert result == {
             :error,
             "File does not exist: non_existent_file.py"
           }
  end
end
