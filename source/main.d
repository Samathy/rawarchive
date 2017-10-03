import std.xml, std.stdio, std.string, std.file, std.conv, std.process, std.path;


int main(string[] args)
{
    string[] archivable_files; //List of files to archive

    foreach ( string filename; dirEntries(".", SpanMode.depth))
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
                archivable_files ~= e.tag.attr["xmpMM:DerivedFrom"]; 
                archivable_files ~= chompPrefix(filename, "./"); 
            }

        }

    }

    archive(archivable_files);

    return 0;
}


void archive(string[] archivable)
{
    //creates an archive and writes all files to it

    //TODO Support custom filenames for archives
    //TODO Support intelligent archive naming based on folder name
    string[] command = ["tar" ,"-czvf", "Rejected_Archive.tar.gz"];
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

