/**
 * message.cc - A class for working with a single message.
 *
 * This file is part of lumail: http://lumail.org/
 *
 * Copyright (c) 2013 by Steve Kemp.  All rights reserved.
 *
 **
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 dated June, 1991, or (at your
 * option) any later version.
 *
 * On Debian GNU/Linux systems, the complete text of version 2 of the GNU
 * General Public License can be found in `/usr/share/common-licenses/GPL-2'
 */

#include <stdint.h>
#include <cstdlib>
#include <iostream>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

#include <mimetic/mimetic.h>

#include <sys/stat.h>
#include <time.h>
#include "lua.h"

#include "file.h"
#include "message.h"
#include "global.h"

using namespace std;
using namespace mimetic;


/**
 * Constructor.
 */
CMessage::CMessage(std::string filename)
{
    m_path = filename;
    m_me   = NULL;
}


/**
 * Destructor.
 */
CMessage::~CMessage()
{
    if ( m_me != NULL )
        delete( m_me );
}


/**
 * Get the path to the message on-disk.
 */
std::string CMessage::path()
{
    return (m_path);
}


/**
 * Update the path to the message.
 */
void CMessage::path( std::string new_path )
{
    m_path = new_path;
}


/**
 * Get the flags for this message.
 */
std::string CMessage::flags()
{
    std::string flags = "";
    std::string pth   = path();

    if (pth.empty())
        return (flags);

    size_t offset = pth.find(":2,");
    if (offset != std::string::npos)
        flags = pth.substr(offset + 3);

    if ( flags.size() > 3)
        flags = "";

    /**
     * Sleazy Hack.
     */
    if ( pth.find( "/new/" ) != std::string::npos )
        flags += "N";


    /**
     * Sort the flags, and remove duplicates
     */
    std::sort( flags.begin(), flags.end());
    flags.erase(std::unique(flags.begin(), flags.end()), flags.end());

    /**
     * Pad.
     */
    while( (int)strlen(flags.c_str()) < 4 )
        flags += " ";

    return flags;
}


/**
 * Add a flag to a message.
 */
void CMessage::add_flag( char c )
{
    /**
     * Flags are upper-case.
     */
    c = toupper(c);

    /**
     * If the flag is already present, return.
     */
    if ( flags().find( c ) == std::string::npos)
        return;

    /**
     * Get the path and ensure it is present.
     */
    std::string p = path();

    if (p.empty())
        return;

    /**
     * Get the current flags.
     */
    size_t offset     = p.find(":2,");
    std::string base  = p;
    std::string flags = "";

    /**
     * If we found flags then add the new one.
     */
    if (offset != std::string::npos)
    {
        flags = p.substr(offset);
        base  = p.substr(0,offset);
    }
    else
    {
        flags = ":2,";
    }

    /**
     * Sleazy Hack.
     */
    if ( p.find( "/new/" ) != std::string::npos )
        flags += "N";

    /**
     * Add the new-flag.
     */
    flags += c;

    CFile::move( p, base + flags );

    /**
     * Update the path.
     */
    path( base + flags );
}


/**
 * Remove a flag from a message.
 */
void CMessage::remove_flag( char c )
{
    /**
     * Flags are upper-case.
     */
    c = toupper(c);

    /**
     * If the flag is not present, return.
     */
    if ( flags().find( c ) == std::string::npos)
        return;

    /**
     * Get the path and ensure it is present.
     */
    std::string p = path();

    if (p.empty())
        return;

    /**
     * Find the flags.
     */
    size_t offset     = p.find(":2,");
    std::string base  = p;
    std::string flags = "";

    /**
     * If we found flags then add the new one.
     */
    if (offset != std::string::npos)
    {
        flags = p.substr(offset);
        base  = p.substr(0,offset);
    }
    else
    {
        flags = ":2,";
    }

    /**
     * Remove the flag.
     */
    std::string::size_type k = 0;
    while((k=flags.find(c,k))!=flags.npos) {
        flags.erase(k, 1);
    }

    /**
     * Move the file.
     */
    CFile::move( p, base + flags );

    /**
     * Update the path.
     */
    path( base + flags );
}


/**
 * Does this message match the given filter?
 */
bool CMessage::matches_filter( std::string *filter )
{
    if ( strcmp( filter->c_str(), "all" ) == 0 )
        return true;

    if ( strcmp( filter->c_str(), "new" ) == 0 ) {
        if ( is_new() )
            return true;
        else
            return false;
    }

    /**
     * Matching the formatted version.
     */
    std::string formatted = format();
    if ( strstr( formatted.c_str(), filter->c_str() ) != NULL )
        return true;

    return false;
}


/**
 * Is this message new?
 */
bool CMessage::is_new()
{
    std::string f = flags();
    if ( f.find( 'N' ) != std::string::npos )
        return true;
    else
        return false;
}


/**
 * Mark the message as read.
 */
bool CMessage::mark_read()
{
    /*
     * Get the current path, and build a new one.
     */
    std::string c_path = path();
    std::string n_path = "";

    size_t offset = std::string::npos;

    /**
     * If we find /new/ in the path then rename to be /cur/
     */
    if ( ( offset = c_path.find( "/new/" ) )!= std::string::npos )
    {
        /**
         * Path component before /new/ + after it.
         */
        std::string before = c_path.substr(0,offset);
        std::string after  = c_path.substr(offset+strlen("/new/"));

        n_path = before + "/cur/" + after;
        if ( rename(  c_path.c_str(), n_path.c_str() )  == 0 ) {
            path(n_path);
            return true;
        }
        else {
            return false;
        }
    }
    else {
        /**
         * The file is new, but not in the new folder.
         *
         * That means we need to remove "N" from the flag-component of the path.
         *
         */
        remove_flag( 'N' );
        return true;
    }
}


/**
 * Mark the message as unread.
 */
bool CMessage::mark_new()
{
    /*
     * Get the current path, and build a new one.
     */
    std::string c_path = path();
    std::string n_path = "";

    size_t offset = std::string::npos;

    /**
     * If we find /cur/ in the path then rename to be /new/
     */
    if ( ( offset = c_path.find( "/cur/" ) )!= std::string::npos )
    {
        /**
         * Path component before /cur/ + after it.
         */
        std::string before = c_path.substr(0,offset);
        std::string after  = c_path.substr(offset+strlen("/cur/"));

        n_path = before + "/new/" + after;
        if ( rename(  c_path.c_str(), n_path.c_str() )  == 0 ) {
            path( n_path );
            return true;
        }
        else {
            return false;
        }
    }
    else {
        /**
         * The file is old, but not in the old folder.  That means we need to
         * add "N" to the flag-component of the path.
         */
        add_flag( 'N' );
        return true;
    }
}


/**
 * Format the message for display in the header - via the lua format string.
 */
std::string CMessage::format( std::string fmt )
{
    std::string result = fmt;

    /**
     * Get the format-string we'll expand from the global
     * setting, if it wasn't supplied.
     */
    if ( result.empty() ) {
        CGlobal *global  = CGlobal::Instance();
        std::string *fmt = global->get_variable("index_format");
        result = std::string(*fmt);
    }

    /**
     * The variables we know about.
     */
    const char *fields[9] = { "FLAGS", "FROM", "TO", "SUBJECT",  "DATE", "YEAR", "MONTH", "DAY", 0 };
    const char **std_name = fields;


    /**
     * Iterate over everything we could possibly-expand.
     */
    for( int i = 0 ; std_name[i] ; ++i) {

        size_t offset = result.find( std_name[i], 0 );

        if ( ( offset != std::string::npos ) && ( offset < result.size() ) ) {

            /**
             * The bit before the variable, the bit after, and the body we'll replace it with.
             */
            std::string before = result.substr(0,offset-1);
            std::string body = "";
            std::string after  = result.substr(offset+strlen(std_name[i]));

            /**
             * Expand the specific variables.
             */
            if ( strcmp(std_name[i] , "TO" ) == 0 ) {
                body = to();
            }
            if ( strcmp(std_name[i] , "DATE" ) == 0 ) {
                body = date();
            }
            if ( strcmp(std_name[i] , "FROM" ) == 0 ) {
                body += from();
            }
            if ( strcmp(std_name[i] , "FLAGS" ) == 0 ) {
                body = flags();
            }
            if ( strcmp(std_name[i] , "SUBJECT" ) == 0 ) {
                body = subject();
            }
            if ( strcmp(std_name[i],  "YEAR" ) == 0 ) {
                body = date(EYEAR);
            }
            if ( strcmp(std_name[i],  "MONTH" ) == 0 ) {
                body = date(EMONTH);
            }
            if ( strcmp(std_name[i],  "DAY" ) == 0 ) {
                body = date(EDAY);
            }

            result = before + body + after;
        }
    }
    return( result );
}


/**
 * Get the value of a header.
 */
std::string CMessage::header( std::string name )
{
    if ( m_me == NULL ) {
        ifstream file(path().c_str());
        m_me = new MimeEntity(file);
    }
    Header & h = m_me->header();
    if (h.hasField(name ) )
        return(h.field(name).value() );
    else
        return "";
}


/**
 * Get the sender of the message.
 */
std::string CMessage::from()
{
    return( header( "From" ) );
}


struct tm *parseDateFmt(CMessage::TDate fmt,std::string date)
{
    static struct tm tm;
    memset(&tm, 0, sizeof(struct tm));

    CLua *lua = CLua::Instance();
    std::vector<std::string> date_fmt = lua->table_to_array( "date_formats" );
    std::vector<std::string>::iterator it;

    for (it = date_fmt.begin(); it != date_fmt.end(); ++it) {
        std::string f = (*it);
        strptime(date.c_str(),f.c_str(), &tm);
        if ( tm.tm_mday != 0 )
            return &tm; 
    }
    return ( NULL );
}

/**
 * Get the date of the message.
 */
std::string CMessage::date(TDate fmt)
{
    std::string date = header("Date");
    struct tm *tm; 

    if (date.empty()) 
    {
        struct stat st_buf;
        const char *p = path().c_str();

        int err = stat(p,&st_buf);
        if ( !err ) {
            time_t modt = st_buf.st_mtime;
            date = ctime(&modt);
            tm 	= localtime (&modt); //XXX: 
        }
    } 
    else 
       tm = parseDateFmt(fmt,date);
    
   
    if ( fmt == EDATE ) 
    	return( date );

    if ( tm != NULL ) 
    {
        char staff[20];
        memset(&tm, 0, 20);
   
    
        if ( fmt == EYEAR ) {
            snprintf( staff,20,"%d",(tm->tm_year + 1900) );
            return std::string(staff);
        }
    }
    return std::string("");

}



/**
 * Get the recipient of the message.
 */
std::string CMessage::to()
{
    return( header( "To" ) );
}


/**
 * Get the subject of the message.
 */
std::string CMessage::subject()
{
    return( header( "Subject" ) );
}


/**
 * Get the body of the message, as a vector of lines.
 */
std::vector<std::string> CMessage::body()
{
    std::vector<std::string> result;

    /**
     * Parse if we've not done so.
     */
    if ( m_me == NULL ) {
        ifstream file(path().c_str());
        m_me = new MimeEntity(file);
    }

    /**
     * The body.
     */
    std::string body;

    /**
     * Iterate over every part.
     */
    mimetic::MimeEntityList& parts = m_me->body().parts();
    mimetic::MimeEntityList::iterator mbit = parts.begin(), meit = parts.end();
    for(; mbit != meit; ++mbit) {

        /**
         * Get the content-type.
         */
        std::string type = (*mbit)->header().contentType().str();

        /**
         * If we've found text/plain then we're good.
         */
        if ( type.find( "text/plain" ) != std::string::npos )
        {
            if ( body.empty() )
                body =  (*mbit)->body();
        }
    }

    /**
     * If we failed to find a part of text/plain then just grab the whole damn
     * thing and hope for the best.
     */
    if ( body.empty() )
        body = m_me->body();


    /**
     * Split the body into an array, by newlines.
     */
    std::stringstream stream(body);
    std::string line;
    while (std::getline(stream, line)) {
        result.push_back( line );
    }

    return(result);
}
