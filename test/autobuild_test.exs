defmodule AutobuildTest do
  use ExUnit.Case

  setup_all do
    # Create file
    source1 = """
    import time
    import time
    import time
    import os
    import os
    import os

    def hello():
        return "Hello"

    """

    source2 = """
    import os
    import os
    import os
    import os
    import time

    def goodbye():
        return "Goodbye"

    """

    File.write!("source1.py", source1, [:write, :binary])
    File.write!("source2.py", source2, [:write, :binary])

    on_exit(fn ->
      File.rm!("source1.py")
      File.rm!("source2.py")
    end)
  end

  test "it can combine python files" do
    paths_and_tags = [
      {"source1.py", "source1"},
      {"source2.py", "source2"}
    ]

    write_to = "output.py"

    Autobuild.combine_files(paths_and_tags, write_to)

    contents = File.read!(write_to)

    expected = """
    import os
    import time


    # ==========
    # File: source1.py
    # Tag: source1
    # ==========

    def hello():
        return "Hello"



    # ==========
    # File: source2.py
    # Tag: source2
    # ==========

    def goodbye():
        return "Goodbye"

    """

    assert contents == expected
  end
end
