import std.xml, std.stdio, std.string, std.file, std.conv, std.process, std.path, std.getopt;


struct options
{
    public:
        bool includeXmp;
        string tar_opts;
        string append;

}
options opts;


/** Concatinates a path to the front of a file name, avoiding 
  lots of extra /s */
string concat_filenames(string path, string filename)
{
    string final_filename;
    if (path[path.length-1] == '/')
    {
        if (filename[0] == '/')
        {
            final_filename = path~filename[1..filename.length];
        }
        else
        {
            final_filename = path~filename;
        }
    }
    else if (filename[0] == '/')
    {
       final_filename = path~filename;
    }
    else
    {
        final_filename = path~"/"~filename;
    }

    return final_filename;

}

unittest 
{
    writeln("Testing concat_filenames");
    assert(concat_filenames("/home/samathy/", "test.cpp") == "/home/samathy/test.cpp");
    assert(concat_filenames("/home/samathy", "/test.cpp") == "/home/samathy/test.cpp");
    assert(concat_filenames("/home/samathy/", "test.cpp") == "/home/samathy/test.cpp");
    assert(concat_filenames("/home/samathy", "test.cpp") == "/home/samathy/test.cpp");
}


int main(string[] args)
{
    /* TODO Add options to support:
       * Optional inclusion of xmp files in archive
       * Different archive options
       * Adding files to the archive
       * Support doing multiple folders
       * Archiving not just rejected files
       * Support for checking RAW files matching XMPs exist.
       */

    string folder;
    string outputFilename;
    string[] archivable_files; //List of files to archive

    getopt(args, "folder|f", &folder, "output|o", &outputFilename, "include-xmp", &opts.includeXmp, "tar-opts|t", &opts.tar_opts, "append|a", &opts.append,);

    if (!folder)
    {    folder = "./";    }
    if (!outputFilename)
    {
        outputFilename = "Rejected_Archive.tar.gz";
    }

    try
    {
    foreach ( string filename; dirEntries(folder, SpanMode.depth))
    {

        if (endsWith(filename, ".xmp")) //TODO support embedded xmp profiles?
        {
            string xmp_file = cast(string) std.file.read(filename);
            std.xml.Document xml = new Document(xmp_file);
            
            std.xml.Element e = xml;

            while (e.tag.name != "rdf:Description") //Lets just hope that the document is NEVER a tree.
            {
                e = e.elements[0];
            }
            
            //TODO Somehow handle case of not having a rating flag

            if (to!int(e.tag.attr["xmp:Rating"]) < 1)
            {
                try 
                {
                    if(exists(concat_filenames(folder, e.tag.attr["xmpMM:DerivedFrom"])))
                    {
                        archivable_files ~= filename;
                        archivable_files ~= concat_filenames(folder, e.tag.attr["xmpMM:DerivedFrom"]); 
                    }
                    else
                    {    throw new FileException(filename); }
                }
                catch (FileException ex)
                {
                    writeln("File Error: "~ex.msg);
                    writeln("Ignoring file "~filename~" and its non-existant companion "~e.tag.attr["xmpMM:DerivedFrom"]);
                    //Do nothing, we just wanted to print the error really
                    continue;
                }
            }

        }

    }
    }
    catch (FileException ex)
    {
        writeln("Critical File Error: "~ex.msg);
        return 0;
    }
    
    if (archivable_files.empty)
    {
        writeln("No files to archive");
        return 0;
    }

    archive(outputFilename, opts.tar_opts, archivable_files);

    return 0;
}


void archive(string outputFilename, string tar_opts, string[] archivable)
{
    //creates an archive and writes all files to it

    //TODO Support custom filenames for archives
    //TODO Support intelligent archive naming based on folder name
    string[] command = ["tar" ,"-czvf"~tar_opts, outputFilename];
    command = command ~ archivable;
    writeln("Archiving the following files: ");
    foreach(string name; archivable)
    {
        write(name~"\n");
    }
    writeln("Into Rejected_Archive.tar.gz");
    //TODO add a 'confirm?' here
    auto tar = execute(command); //Error check TAR command
    writeln("\ntar output: ");
    writeln(tar.output);

    //Delete files after archive

    return;

}

