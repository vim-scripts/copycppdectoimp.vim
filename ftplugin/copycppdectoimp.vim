" vim:ff=unix ts=4 ss=4
" vim60:fdm=marker
" \file		copycppdectoimp.vim
" \date		Tue, 03 Jun 2003 02:21 Pacific Daylight Time
"
" \brief	This provides a function that you can call in your header file
"			(with cursor on the function to be placed into your souce file) and
"			then called from your source file where you want the function
"			definition to be placed and the function makes it all pretty and
"			does most of the work for you. Pretty handy.
" \note		This is VIMSCRIPT#437,
"			http://vim.sourceforge.net/script.php?script_id=437
"
" \note		From VIM-Tip #335: Copy C++ function declaration into
"			implementation file by Leif Wickland
"			See: http://vim.sourceforge.net/tip_view.php?tip_id=335
" \note		For a similar idea see Luc Hermitte's VIMSCRIPT#336,
"			(cpp_InsertAccessors.vim in particular)
"			http://vim.sourceforge.net/scripts/script.php?script_id=336
"			http://hermitte.free.fr/vim/
"
" \author	Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
" \author	Original idea/implimentaion: Leif Wickland
" \note		Emial addresses are Rot13ed. Place cursor in the <> and do a g?i<
" \note		This file and work is based on Leif Wickland's VIM-TIP#335
" \version	$Id: copycppdectoimp.vim,v 1.3 2002/10/29 06:14:16 root Exp $
" Version:	0.46
" History: {{{
"	[Feral:154/03@02:12] 0.46
"		Refined matching declaration prens; should be more resistant to
"		mismatched prens outside of the function declaration. Mismatched prens
"		inside the function declaration (i.e. in comments) will confuse this
"		still.
"	[Feral:124/03@02:13] 0.45
"		Bug fix: more robust handling of comments and prens and things in
"			multi line function declorations.
"	[Feral:095/03@00:33] 0.44
"		* Small fix to take into account non blank equalprg; thanks to Nathan
"			Dunn for help tracking this down.
"	[Feral:290/02@06:15] 0.43
"		* Bugfix, The case of filename extension no loger matters during the
"			check for header/source.
"	[Feral:288/02@08:49] 0.42
"		namespaces and destructors now are handled properly.
"	Improvments:
"		* properly handles namespaces, thanks to Russell for pointing this
"			out.
"		* Proprly handles class destructors, Thanks to Andy for pointing this
"			out.
"	[Feral:287/02@00:32] 0.41
"		Drat.
"	Improvments:
"		* Fixed a fold marker bungle (had a mismated closing foldmarker at the
"			end of this comment block. erm, oops.)
"		* Bugfix: Using setlocal now. (as a ftplugin should)
"		* More Cleanup.
"		* Can be invoked in the middle of a multi line function decloration
"			now, much better.
"		* Now uses global vars to decide what commands to define, defaulting
"			to :GHPH. See ||@|GHPH Options| below
"	Limitations:
"		* (recap) A inlined function with no (); construct will not be
"			recognised as a function.
"	[Feral:286/02@16:58] 0.4
"		Thanks to Andy for pointing out that inlined functions caused this to
"		fail.
"	Improvments:
"		* Changed method to find the class, now works with inlined functions.
"		* Added :GH and :PH remed, unrem if you want to use them.
"		* General Script Cleanup (I hope!)
"		* Replaced function params with global vars for options; allows
"			onthefly option changing.
""
"			(I hope you consider it an improvement anyway (: if you do not you
"			can basicaly ignore this fancy smacy global var stuff by unremming
"			the :lets at the command definition below and then forgetting them
"			:) )
"	Limitations:
"		* A inlined function with no (); construct will not be recognised as a
"			function.
"		* (recap) Must be invoked on the line that starts the the function
"			decloration. -- I'll probably get around to doing something with
"			this limitation eventually.
"	[Feral:283/02@16:42] 0.33
"		Thanks again goto Rostislav for ideas and suggestions
"	Improvments:
"		* Proper FTPlugin now, at least I think.
"		* struct and nested structs workie now too.
"		* can specify an override param and have :GHPH paste or get
"			regardless of the file type it's in. i.e. :GHPH p or :GHPH g
"		* added .hpp, .hh, .hxx as recognizable header files.
"	[Feral:282/02@17:03] 0.32
"		Rather large change to support nested classes. Ok not THAT large.
"		Thanks to Rostislav for pointing this out.
"		Using searchpair to find the class inspired by Luc Hermitte.
"	Improvments:
"		* More intelligent/robust checking/finding the class.
"		* Nested classes are now supported.
"		* Normal functions now work.
"	[Feral:281/02@16:24] 0.31
"		as Rostislav Julinek pointed out [[ does not work when the brace is not
"			in col 1. If you like your braces after your class definition this
"			should do the trick for you.
"	[Feral:278/02@00:29] 0.3
"	Improvments:
"		* fairly drastic improvement. Now works with multi-line function
"			declarations as long as they are properly closed(open prens will
"			make this fail), aka if it compiles it should work.
"	Limitation:
"		* Must be invoked on the line that starts the the function decloration.
"	[Feral:275/02@14:50] 0.21
"		* Itty bitty file format changes, email address is Rot13ed now,
"			documtation and command defintions are folded.
"		* Slight improvement(?) in fetching the line, in a script so why not
"			getline(".") eh?
"	[Feral:274/02@20:42] 0.2
"	Improvments: from Leif's Tip (#335):
"		* can handle any number of default prams (as long as they are all on
"			the same line!)
"		* Options on how to format default params, virtual and static. (see
"			below) TextLink:||@|Prototype:|
"		* placed commands into a function (at least I think it's an improvement
"			;) )
"		* Improved clarity of the code, at least I hope.
"		* Preserves registers/marks. (rather does not use marks), Should not
"			dirty anything.
"		* All normal operations do not use mappings i.e. :normal!
"			(I have Y mapped to y$ so Leif's mappings could fail for me.)
"
"	Limitations:
"		* fails on multi line declorations. All prams must be on the same line.
"		* fails for non member functions. (though not horibly, just have to
"			remove the IncorectClass:: text...
"	0.1
"		Leif's original VIM-Tip #335
" }}}
" Ideas Thoughts And Possible Expansions: {{{ Feedback requested.
"	Should This Also Manage Data Members:? {{{2
"		(basicaly mearge what I did with getset.vim into this.)
"		Advantages:
"		* No need to remember another command (of course one could easily make
"			a stub that calls this or getset (for instance) based on the
"			contents of the lne.
"
"			Or stub this to call getset if the line does not register as a
"				function decloration, which is probably what I'll end up doing
"				if no one cares... [Feral:286/02@17:53]
"		Disadvantages:
"		* Would clutter up the code and if you already have a getset type
"			thing (Luc has a very nice one) it's pointless wasted space.
"			(Unless it is just I just call another func when I think it's a
"			member var.)
"
"	Handel Template Functions: {{{2
"		Ideas from Rostislav and Luc
"		What do these things look like anyway? -- I have not messed with
"			templates enough to know the ins and outs of them, examples wanted!
"
"	End: {{{2
"	}}}2
" }}}

"Place something like the below in your .vimrc or whereever you like to keep
"	your global option vars and change as desired.
""
""*****************************************************************
"" GHPH Options: {{{
""*****************************************************************
"" See copycppdectoimp.vim for more documtation.
"" Virtual: 1 for commented, else removed.
"let g:ghph_ShowVirtual			= 0
"" Static:  1 for commented, else removed.
"let g:ghph_ShowStatic 			= 0
"" Default Params: 3 for /*5*/, 2 for /* = 5*/, else removed.
"let g:ghph_ShowDefaultParams	= 3
"" Command: 1 to define :GHPH (default if nothing defined), 0 to NOT define.
"let g:ghph_useGHPH				= 1
"" Command: 1 to define :GH and :PH, 0 to NOT define.
"let g:ghph_useGHandPH			= 1
"" }}}
""

if exists("b:loaded_copycppdectoimp")
	finish
endif
let b:loaded_copycppdectoimp = 1


"*****************************************************************
" Functions: {{{

if !exists("*s:GrabFromHeaderPasteInSource(...)")
function s:GrabFromHeaderPasteInSource(...) "{{{
	let l:WhatToDo = 0 " 0 = get header, else put header.
	" [Feral:283/02@15:40] sort of guessing on extesions here.. I tend to only
	"	use .h ...
	" [Feral:123/03@23:59] Could \<h perhaps. (i.e. if ext starts with h
	"	consider it a header.)
	if match(expand("%:e"), '\c\<h\>\|\<hpp\>\|\<hh\>\|\<hxx\>') > -1
		let l:WhatToDo = 0
	else
		let l:WhatToDo = 1
	endif

	" Just for clarity override the above as a separate if
	if a:0 == 1
		if a:1 == '0' || a:1 ==? "h" || a:1 ==? "g"
			let l:WhatToDo = 0
		elseif a:1 == '1' || a:1 ==? "c" || a:1 ==? "p"
			let l:WhatToDo = 1
		else
			echo "GHPH: ERROR: Unknown option"
			return
		endif
	endif
"	echo confirm("l:WhatToDo:".l:WhatToDo)



	" handle options
"	if exists("g:cpp_ShowVirtual")
"		let howtoshowVirtual		= g:cpp_ShowVirtual
"	else
	if exists('g:ghph_ShowVirtual')
		let howtoshowVirtual		= g:ghph_ShowVirtual
	else
		let howtoshowVirtual		= 0
	endif

"	if exists("g:cpp_ShowStatic")
"		let howtoshowStatic			= g:cpp_ShowStatic
"	else
	if exists('g:ghph_ShowStatic')
		let howtoshowStatic			= g:ghph_ShowStatic
	else
		let howtoshowStatic			= 0
	endif

"	if exists("g:cpp_ShowDefaultParams")
"		let howtoshowDefaultParams	= g:cpp_ShowDefaultParams
"	else
	if exists('g:ghph_ShowDefaultParams')
		let howtoshowDefaultParams	= g:ghph_ShowDefaultParams
	else
		let howtoshowDefaultParams	= 3
	endif



	" Now do something!
	if l:WhatToDo == 0
		" {{{ GET the header
		" save our position
		let SaveL = line(".")
		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"



		" [Feral:287/02@00:58] Rearangement and now works when cursor is in
		" the middle of a multi line decloration.
		" [Feral:277/02@12:54] In an attempt to grab the entire multi line
		" function decloration (I often have a param per line with comments)
		" do a searchpair to find the last pren.
"		let StartLine = line('.')
		" if there is a ( in the line, goto it in prep for our searchpair.
		if stridx(getline('.'), '(') > -1
			execute "normal! 0f("
		endif
		" Important that End comes first, this gets us into the ()...
		" [Feral:154/03@02:02] Find the outermost () pair but ensure that the
		"	closing pren is followed by a ; on the same line.
		let EndLine = searchpair('(','',').\{-};', 'rW')

"		echo confirm("This is end ".EndLine."\n".getline(EndLine))

		" goto the start of the pren, this should be the line with the function decloration
"		let StartLine = searchpair('(','',').\{-};', 'b')
"		let StartLine = searchpair('(','',')', 'br')
		" [Feral:154/03@01:56] searchpair to find end; already found the outer
		"	match, just find it's pair now.
		let StartLine = searchpair('(','',')', 'bW')


"		echo confirm("This is start ".StartLine."\n".getline(StartLine))

		if EndLine == 0 || StartLine == 0
			echo "GHPH: ERROR: Sorry this does not look like a function decloration, missing '(' and or ')' with trailing ';'"
			return
		endif


		:let Was_Reg_l = @l
		":[range]y[ank] [x]	Yank [range] lines [into register x].
		execute ":".StartLine.",".EndLine."yank l"
		:let s:LineWithDecloration = @l
		:let @l=Was_Reg_l
"		echo confirm(s:LineWithDecloration)

"[Feral:093/03@16:49] In dev, probaly should be some informative message if s:LineWithDecloration is bad. (define bad)
"		if s:LineWithDecloration == ""
"			echo "GHPH: ERROR: Unable to find"
"		endif
		let s:LineWithDeclorationSize = ( (EndLine - StartLine) + 1)
"		echo confirm(s:LineWithDeclorationSize)

"		"[Feral:282/02@17:03] Rather large change to support nested classes
"		"	and as a side benefit normal functions now work.
" {{{ Mark I -- Old code
"		let s:ClassName = ""
"		let mx='\<class\>\s\{-}\(\<\I\i*\)\s\{-}.*'
"		while searchpair('\<class\>.\{-}\n\=\s\{-}{','','}', 'bW') > 0
"			let DaLine = getline('.')
"			let Lummox = matchstr(DaLine, mx)
"			let s:ClassName = substitute(Lummox, mx, '\1', '') . '::' . s:ClassName
""			echo confirm(s:ClassName)
"		endwhile
" }}}
		"[Feral:283/02@16:29] Good idea Rostislav, lets support structs too!
" {{{ Mark II -- Old code
"		let s:ClassName = ""
"		let mx='\%(\<class\>\|\<struct\>\)\s\{-}\(\<\I\i*\)\s\{-}.*'
"		while searchpair('\%(\<class\>\|\<struct\>\).\{-}\n\=\s\{-}{','','}', 'bW') > 0
"			let DaLine = getline('.')
"			let Lummox = matchstr(DaLine, mx)
"			let s:ClassName = substitute(Lummox, mx, '\1', '') . '::' . s:ClassName
""			echo confirm(s:ClassName)
"		endwhile
""		echo confirm('s:ClassName('.s:ClassName.')')
" }}}
		"[Feral:285/02@23:28] Andy found this to not work.
		"Current Version: Mark III
" {{{ Mark III
"class testing
"{
"public:
"    virtual void hithere(int x = 4);
"    int dootdedoo(bool x, bool y, bool z) { printf("doot de doo...\n"); }
"    virtual void hithere2(int x = 5);
"}
"[Feral:286/02@06:08] Probably have to be a two part search. one {} searchpair
"so inline function defs are skiped and then a search to find the
"class/struct.. if we no find pair, we done. If we no find class, we done.
":echo searchpair('{','','}', 'bW')
":echo search('\%(\<class\>\|\<struct\>\).\{-}\n\=\s\{-}{', 'bW')
"[Feral:286/02@06:16] Yes, this seems to work. Tired now, double check later.
"[Feral:286/02@16:43] Workie fine, or so it seems.
"[Feral:288/02@08:07] Russell mentions that namespaces do not work, lets fix that.
"namespace myNamespace {
"    class someClass {
"      public:
"         int doSomething( int i );
"    };
"}
		let s:ClassName = ""
		let mx='\(\<class\>\|\<struct\>\|\<namespace\>\)\s\{-}\(\<\I\i*\)\s\{-}.*'
		while 1
			if searchpair('{','','}', 'bW') > 0
				if search('\%(\<class\>\|\<struct\>\|\<namespace\>\).\{-}\n\=\s\{-}{', 'bW') > 0
					let DaLine = getline('.')
					let Lummox = matchstr(DaLine, mx)
"					let s:ClassName = substitute(Lummox, mx, '\1', '') . '::' . s:ClassName
					let FoundType = substitute(Lummox, mx, '\1', '')
					let FoundClassName = substitute(Lummox, mx, '\2', '')
"					echo confirm(FoundClassName.' is a '.FoundType)
					if FoundType !=? 'namespace' && FoundType != ''
						let s:ClassName = FoundClassName.'::'.s:ClassName
					endif
				else
					echo confirm("copycppdectoimp.vim:DEV:Found {} but no class/struct\nIf this was a proper function and you think it should have worked, email me the (member) function/class setup and I'll see if I can get it to work.(email is in this file)")
				endif
			else
				break
			endif
		endwhile
"		echo confirm('s:ClassName('.s:ClassName.')')
" }}}


		" go back to our saved position.
		:execute ":normal! ".SaveT."Gzt"
		:execute ":normal! ".SaveL."G"
		:execute ":normal! ".SaveC."|"

"		echo confirm(s:ClassName)
		" }}}
	else
		" {{{PUT the header

		" -[Feral:283/02@16:06]-----------------------------------------------
		" Gate
		" [Feral:283/02@16:07] Gate
		if !exists("s:LineWithDecloration")
			echo "GHPH: ERROR: I do not have an implimentation to work with!"
			return
		endif

"		echo confirm(s:ClassName)
		let SaveL = line(".")
"		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"
"		:execute ':normal! ma'
		:let Was_Reg_n = @n
		:let @n=@/


		" [Feral:277/02@23:02] Multi-line version.
		:let Was_Reg_l = @l
		:let @l = s:LineWithDecloration
"		echo confirm(@l)
		execute 'normal! "lP'
		:let @l=Was_Reg_l
"		echo confirm(line('.'))
"		echo confirm(s:LineWithDeclorationSize)

		" Remove end of line comments for multi line...
"		echo confirm(line('.'))
		let SaveReport = &report
		setlocal report=9999
		let Save2L = line(".")
		execute ':'.Save2L.','.(Save2L+s:LineWithDeclorationSize-1).'s/\s\{-}\/[/*].\{-}$//e'
		:execute ":normal! ".Save2L."G"
"		echo confirm(line('.'))
"		let &report=SaveReport
		execute "setlocal report=".SaveReport

		" join multi line into one line
		if s:LineWithDeclorationSize > 1
"			echo confirm('Jing '.s:LineWithDeclorationSize.' times...')
			:execute ':normal! '.s:LineWithDeclorationSize.'J'
"			:execute ':join '.s:LineWithDeclorationSize
"			:execute ':'.Save2L.','.(Save2L+s:LineWithDeclorationSize-1).'join '

			" [Feral:278/02@00:17] Get rid of tabs and replace with a single space
			execute ':s/\t\+/ /ge'
			" [Feral:278/02@00:18] Fix up that initial FuncName( param_type param, pt2 param2)
			" I do not like the space between the Function Name the pren and the param. (caused by J)
			execute ':s/\(\i(\) /\1/e'
		endif

		" [Feral:095/03@00:07] Small fix for when equalprg is defined, oopsie!
		"	Thanks to Nathan Dunn for help tracking this down.
		let Was_EqualPrg = &equalprg
		"	seems == does not use a local equalprg, dern.
		set equalprg=""
		execute ':normal! =='
		execute "set equalprg=".Was_EqualPrg

		" XXX if you want virtual commented in the implimentation:
		if howtoshowVirtual == 1
			execute ':s/\<virtual\>/\/\*&\*\//e'
		else
			" XXX else, remove virtual and any spaces/tabs after it.
			execute ':s/\<virtual\>\s*//e'
		endif

		" XXX if you want static commented in the implimentation:
		if howtoshowStatic == 1
			execute ':s/\<static\>/\/\*&\*\//e'
		else
			" XXX else, remove static and any spaces/tabs after it.
			execute ':s/\<static\>\s*//e'
		endif

		" wipe out a pure virtual thingie-ma-bob. (technical term? (= )
		execute ':s/)\s\{-}=\s\{-}0\s\{-};/);/e'

		" Handle default params, if any.
		if howtoshowDefaultParams == 1
			" Remove the default param assignments.
			execute ':s/\s\{-}=\s\{-}[^,)]\{1,}//ge'
		else
			" Comment the default param assignments.
			execute ':s/\s\{-}\(=\s\{-}[^,)]\{1,}\)/\/\*\1\*\//ge'

			if howtoshowDefaultParams == 3
				" Remove the = and any spaces to the left or right.
				execute ':s/\s*=\s*//ge'
			endif
		endif

		let @/=@n
		let @n=Was_Reg_n
		execute ":normal! ".SaveT."Gzt"
		execute ":normal! ".SaveL."G"
"[Feral:288/02@08:29] Andy mentions destructors are well, broken. Duh how
"could I forget destructors anyway?
		if s:ClassName !=# ""
			if stridx(getline('.'), '~') > -1
				execute ':normal! 0f(F~'
			else
				execute ':normal! 0f(b'
			endif
			execute ':normal! i'.s:ClassName
		endif
"		:execute ":normal! ".SaveC."|"

		" find the ending ; and replace it with a brace structure on the next line.
"		:execute ":normal! f;s\<cr>{\<cr>}\<cr>\<esc>2k"
		:execute ":normal! f;s\<cr>{\<cr>}\<esc>k"
		" }}}
	endif

endfunc	" }}}
endif

" }}} EO Functions
"*****************************************************************
" Documtation: {{{
"*****************************************************************
" Script Function Prototype:
"GrabFromHeaderPasteInSource(VirtualFlag, StaticFlag, DefaultParamsFlag)
"
" Given:
"	virtual void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");
"
" VirtualFlag:
" let g:ghph_ShowVirtual		= 1
"	If you want virtual commented in the implimentation:
"	IE: /*virtual*/ void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");
" let g:ghph_ShowVirtual		= 0
"	If you want virtual and any spaces/tabs after it removed.
"	IE: void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");
"
" StaticFlag:
" let g:ghph_ShowStatic			= 1
"	If you want static commented in the implimentation:
"	IE: Same as virtual, save deal with static
" let g:ghph_ShowStatic			= 0
"	If you want static and any spaces/tabs after it removed.
"	IE: Same as virtual, save deal with static
"
" DefaultParamsFlag:
" Note: darn bungled I see, no entry for 0 ... OOPS (:
" let g:ghph_ShowDefaultParams	= 1
"	If you want to remove default param reminders
"	IE: Test_Member_Function_B3(int _iSomeNum2, char * _cpStr);
" let g:ghph_ShowDefaultParams	= 2
"	If you want to comment default param assignments
"	IE: Test_Member_Function_B3(int _iSomeNum2/*= 5*/, char * _cpStr/*= "Yea buddy!"*/);
" let g:ghph_ShowDefaultParams	= 3
"	Like 2 but, If you do not want the = in the comment
"	IE: Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
"
" Examples:
"	Smallest Implimentation:
" let g:ghph_ShowVirtual		= 0
" let g:ghph_ShowStatic			= 0
" let g:ghph_ShowDefaultParams	= 1
"	IE: void Test_Member_Function_B3(int _iSomeNum2, char * _cpStr);
"	Verbose:
" let g:ghph_ShowVirtual		= 1
" let g:ghph_ShowStatic			= 1
" let g:ghph_ShowDefaultParams	= 3
"	IE: /*virtual*/ void Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
"	What I Like: (and the default)
" let g:ghph_ShowVirtual		= 0
" let g:ghph_ShowStatic			= 0
" let g:ghph_ShowDefaultParams	= 3
"	IE: void Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
"
" Override: (for :GHPH only)
" If you would like to override the default action (i.e. you want to paste the
"	implimentation in your header file) you can specify an overide value on
"	the command line or as the optional parameter for
"	GrabFromHeaderPasteInSource().
"	Valid Override values are (text in the quotes) '0','h','g' to get the
"	decloration and '1','c' and 'p' to put (and make) the decloration.
"	See below under commands for an example :GH and :PH
"
"
" Bit of trivia... GHPH.. get header, put (althought half the time I think
"	paste heh) header. ~shrug~ I needed a command name.... (Name it whatever
"	you wish, of course!)
" }}}
"*****************************************************************
" Inspiration: {{{
"{{{ [basic]  Tip #335: Copy C++ function declaration into implementation file
" tip karma   Rating 5/2, Viewed by 49 
"
"created:   October 1, 2002 6:47      complexity:   basic
"author:   Leif Wickland      as of Vim:   5.7
"
"There's a handy plug in for MS Visual Studio called CodeWiz that has a nifty ability to copy a function declaration and deposit it into the implementation file on command.  I actually missed while using vim, so I wrote an approximation of that capability.  This isn't foolproof, but it works alright.  
"
"" Copy Function Declaration from a header file into the implementation file.
"nmap <F5> "lYml[[kw"cye'l
"nmap <F6> ma:let @n=@/<cr>"lp==:s/\<virtual\>/\/\*&\*\//e<cr>:s/\<static\>/\/\*&\*\//e<cr>:s/\s*=\s*0\s*//e<cr>:s/(.\{-}\zs=\s*[^,)]\{-1,}\>\ze\(\*\/\)\@!.*)/\/\*&\*\//e<cr>:s/(.\{-}\zs=\s*[^,)]\{-1,}\>\ze\(\*\/\)\@!.*)/\/\*&\*\//e<cr>:s/(.\{-}\zs=\s*[^,)]\{-1,}\>\ze\(\*\/\)\@!.*)/\/\*&\*\//e<cr>:let @/=@n<cr>'ajf(b"cPa::<esc>f;s<cr>{<cr>}<cr><esc>kk
"
"To use this, source it into vim, for example by placing it in your vimrc, press F5 in normal mode with the cursor on the line in the header file that declares the function you wish to copy.  Then go to your implementation file and hit F6 in normal mode with the cursor where you want the function implementation inserted.
" }}}
" Bits and pieces of Luc's scripts :)
" }}}
"*****************************************************************
" Commands: {{{
"*****************************************************************
" NOTE: [Feral:286/02@19:02] If you would like to NOT mess with the global var
"	stuff and just want to define your options here, just unrem these lets and
"	set your values
"let g:ghph_ShowVirtual			= 1
"let g:ghph_ShowStatic			= 1
"let g:ghph_ShowDefaultParams	= 2
"" to Define :GHPH
"let g:ghph_useGHPH				= 1
"" to Define :GH and :PH
"let g:ghph_useGHandPH			= 1

" default command choice:
if !exists('g:ghph_useGHPH') && !exists('g:ghph_useGHandPH')
	let g:ghph_useGHPH			= 1
"	let g:ghph_useGHandPH		= 1
endif

" GHPH Usage: {{{
"	In Header:
"		:GHPH
"	In Source:
"		:GHPH
"	Putting A Implimentation While In A Header:
"		:GHPH p
"	Getting A Decloration While In A Source File:
"		:GHPH g
" }}}
if !exists(":GHPH") && exists('g:ghph_useGHPH')
	if g:ghph_useGHPH == 1
:command -buffer -nargs=? GHPH call <SID>GrabFromHeaderPasteInSource(<f-args>)
	endif
endif

"[Feral:286/02@17:08] More normal commands, one to get the header and one to
"	paste the header.
" GH And PH Usage: {{{
"	In Header:
"		:GH
"	In Source:
"		:PH
"	Putting A Implimentation While In A Header:
"		:PH
"	Getting A Decloration While In A Source File:
"		:GH
"	Note:
"	This is very straight forward, when you want to get a decloration you :GH
"		when you want to put a implimentation you :PH
" }}}
if !exists(":GH") && exists('g:ghph_useGHandPH')
	if g:ghph_useGHandPH == 1
:command -buffer -nargs=0 GH call <SID>GrabFromHeaderPasteInSource('g')
	endif
endif

if !exists(":PH") && exists('g:ghph_useGHandPH')
	if g:ghph_useGHandPH == 1
:command -buffer -nargs=0 PH call <SID>GrabFromHeaderPasteInSource('p')
	endif
endif
"}}}
"*****************************************************************




"
" EOF
