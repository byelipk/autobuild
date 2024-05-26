defmodule Autobuild.FilewriterTest do
  use ExUnit.Case

  test "it concatenates multiple statement tuples into into file" do
    statements = [
      {
        :ok,
        "example.py",
        [
          "import os\n",
          "import sys\n",
          "import time\n"
        ],
        [
          "\n",
          "def hello():\n",
          "    return \"World\"\n",
          "\n"
        ],
        "testing1.py"
      },
      {
        :ok,
        "example2.py",
        [
          "import os\n",
          "import sys\n",
          "import time\n"
        ],
        [
          "\n",
          "def goodbye():\n",
          "    return \"Goodbye\"\n",
          "\n"
        ],
        "testing2.py"
      }
    ]

    filename = "output.py"

    Autobuild.Filewriter.write_file(statements, filename)

    contents = File.read!(filename)

    expected = """
    import os
    import sys
    import time


    # ==========
    # File: example.py
    # Tag: testing1
    # ==========

    def hello():
        return "World"



    # ==========
    # File: example2.py
    # Tag: testing2
    # ==========

    def goodbye():
        return "Goodbye"

    """

    assert contents == expected

    File.rm!(filename)
  end
end
