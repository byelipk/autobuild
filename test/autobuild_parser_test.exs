defmodule Autobuild.ParserTest do
  use ExUnit.Case

  test "it can hoist_imports a list of imports correctly" do
    lines = [
      "import os\n",
      "import sys\n",
      "import time\n",
      "from poop import pee\n",
      "from datetime import (\n",
      "    datetime,\n",
      "    timedelta,\n",
      ")\n",
      "import time\n",
      "import time\n",
      "import os\n",
      "from poop import pee\n",
      "import time\n",
      "from foo import (bar, baz)\n",
      "from foo import (bar, baz)\n",
      "from foo import (bar, baz)\n",
      "import time\n",
      "import time\n"
    ]

    results = Autobuild.Parser.hoist_imports(lines)

    assert results == [
             "from datetime import (datetime, timedelta)\n",
             "from foo import (bar, baz)\n",
             "from poop import pee\n",
             "import os\n",
             "import sys\n",
             "import time\n"
           ]
  end

  test "it can dedupe and sort imports" do
    lines = [
      "from foo import pee\n",
      "import baz\n",
      "from foo import poop\n",
      "from foo import (drink, drugs)\n",
      "import bar\n"
    ]

    results = Autobuild.Parser.dedupe_imports(lines)

    assert results == [
             "from foo import (drink, drugs, pee, poop)\n",
             "import bar\n",
             "import baz\n"
           ]
  end

  test "it can pull tags from source lines" do
    lines = [
      "import os\n",
      "import sys\n",
      "import time\n",
      "\n",
      "# ==========\n",
      "# File: example.py\n",
      "# Tag: testing1\n",
      "# ==========\n",
      "\n",
      "def hello():\n",
      "    return \"World\"\n",
      "\n",
      "# ==========\n",
      "# File: example2.py\n# Tag: testing2\n# ==========\n",
      "\n",
      "def goodbye():\n",
      "    return \"Goodbye\"\n",
      "\n"
    ]

    results = Autobuild.Parser.pull_tags(lines)

    assert results == [
             "testing1",
             "testing2"
           ]
  end

  test "it can purge imports" do
    import_lines = [
      "import bar\n",
      "import baz\n",
      "from foo import poop\n"
    ]

    source_lines = [
      "import bar\n",
      "import baz\n",
      "from foo import poop\n",
      "\n",
      "# Tag: foo\n",
      "def poop():\n",
      "    return \"poop\"\n",
      "\n"
    ]

    results = Autobuild.Parser.purge_imports(import_lines, source_lines)

    assert results == [
             "import bar\n",
             "import baz\n"
           ]
  end

  test "it throws is source is malformatted" do
    lines = [
      "import time\n",
      "def hello():\n",
      "    return \"World\"\n",
      "\n",
      "import os\n"
    ]

    try do
      Autobuild.Parser.hoist_imports(lines)
    rescue
      RuntimeError -> assert true
    end
  end

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
    stream = File.stream!("example.py", [:line])

    result = Autobuild.Parser.readlines(stream)

    assert result ==
             {:ok, ["import os\n", "import sys\n", "import time\n"],
              [
                "\n",
                "def hello():\n",
                "    return \"World\"\n",
                "\n",
                "def goodbye():\n",
                "    return \"Goodbye\"\n",
                "\n"
              ]}

    File.rm!("example.py")
  end

  test "it can pull all tags out of source lines" do
    lines = [
      "import os\n",
      "import sys\n",
      "import time\n",
      "\n",
      "# ==========\n",
      "# File: example.py\n",
      "# Tag: testing1\n",
      "# ==========\n",
      "\n",
      "def hello():\n",
      "    return \"World\"\n",
      "\n",
      "# ==========\n",
      "# File: example2.py\n",
      "# Tag: testing2\n",
      "# ==========\n",
      "\n",
      "def goodbye():\n",
      "    return \"Goodbye\"\n",
      "\n"
    ]

    results = Autobuild.Parser.pull_tags(lines)

    assert results == [
             "testing1",
             "testing2"
           ]
  end
end
