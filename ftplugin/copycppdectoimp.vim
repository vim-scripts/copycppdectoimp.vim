" vim:ff=unix ts=4 ss=4
" vim60:fdm=marker
" \file		copycppdectoimp.vim
"
" \brief	This provides a function that you can call in your header file
"			(with cursor on the function to be placed into your souce file) and
"			then called from your source file where you want the function
"			definition to be placed and the function makes it all pretty and
"			does most of the work for you. Pretty handy.
" \note		From VIM-Tip #335: Copy C++ function declaration into
"			implementation file by Leif Wickland
"			See: http://vim.sourceforge.net/tip_view.php?tip_id=335
"
" \author	Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
" \author	Original idea/implimentaion: Leif Wickland
" \note		Emial addresses are Rot13ed. Place cursor in the <> and do a g?i<
" \note		This file and work is based on Leif Wickland's VIM-TIP#335
" \date		Wed, 09 Oct 2002 17:33 Pacific Daylight Time
" \version	$Id$
" Version:	0.32
" History: {{{
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

if exists("loaded_copycppdectoimp")
	finish
endif
let loaded_copycppdectoimp = 1

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

function! <SID>GrabFromHeaderPasteInSource(howtoshowVirtual, howtoshowStatic, howtoshowDefaultParams) "{{{
"	echo confirm(expand("%:e"))
	if expand("%:e") ==? "h"

"nmap <F5> "lYml[[kw"cye'l
"		execute ":normal! ml"
		let SaveL = line(".")
		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"

"		" into l yank the entire line
"		" ([Feral:274/02@19:06] MY Y is mapped to y$, so I account for that below)
"		:let Was_Reg_l = @l
""		execute ':normal! "lY'
"		execute ':normal! 0"ly$'
""		echo confirm(@l)
"		:let s:LineWithDecloration = @l
"		:let @l=Was_Reg_l

"		" [Feral:277/02@13:05] Single line version.
"		let s:LineWithDecloration = getline(".")

" void SomeFunc(void);				// Some comment.
" void SomeFunc(int _iSomevar);
" void SomeFunc(int _iSomevar
" void SomeFunc(
"				int _iHowOdd,		//!< Doxygen style param comment
"				long _lInteresting,	//!< Ditto
"				float _fYea			//!< this too.
"				);
"echo searchpair('(','',').*;', 'n')

		" [Feral:277/02@12:54] In an attempt to grab the entire multi line
		" function decloration (I often have a param per line with comments)
		" do a searchpair to find the last pren.
"	if searchpair('(','',')', 'n') > 0
		let StartLine = line('.')
		execute "normal! 0f("
		let EndLine = searchpair('(','',').*;', 'n')
		if EndLine == 0
			echo confirm("Sorry this does not look like a function decloration (no prens();!)")
			return
		endif

		:let Was_Reg_l = @l
		":[range]y[ank] [x]	Yank [range] lines [into register x].
		execute ":".StartLine.",".EndLine."yank l"
"		echo confirm("S: ".StartLine."; EndLine: ".EndLine.";")
"		echo confirm(@l)
		:let s:LineWithDecloration = @l
		:let @l=Was_Reg_l
"		echo confirm(s:LineWithDecloration)
		let s:LineWithDeclorationSize = ( (EndLine - StartLine) + 1)

		"[Feral:282/02@17:03] Rather large change to support nested classes
		"and as a side benefit normal functions now work.
		let s:ClassName = ""
		let mx='\<class\>\s\{-}\(\<\I\i*\)\s\{-}.*'
		while searchpair('\<class\>.\{-}\n\=\s\{-}{','','}', 'bW') > 0
			let DaLine = getline('.')
			let Lummox = matchstr(DaLine, mx)
			let s:ClassName = substitute(Lummox, mx, '\1', '') . '::' . s:ClassName
"			echo confirm(s:ClassName)
		endwhile
"		echo confirm(s:ClassName)


"		execute ":normal! 'l"
		:execute ":normal! ".SaveT."Gzt"
		:execute ":normal! ".SaveL."G"
		:execute ":normal! ".SaveC."|"

"		echo confirm(s:ClassName)
	else
"		echo confirm(s:ClassName)
		let SaveL = line(".")
		let SaveC = virtcol(".")
		" :help restore-position
		execute ":normal! H"
		let SaveT = line('.')
		execute ":normal! ".SaveL."G"
"		:execute ':normal! ma'
		:let Was_Reg_n = @n
		:let @n=@/

		" [Feral:277/02@13:11] Old one line version
"		:execute ':normal! O'.s:LineWithDecloration
"		:execute ':normal! =='
		" [Feral:277/02@23:02] Multi-line version.
		:let Was_Reg_l = @l
		:let @l = s:LineWithDecloration
"		echo confirm(@l)
		execute 'normal! "lP'
		:let @l=Was_Reg_l
"		echo confirm(line('.'))
"		echo confirm(s:LineWithDeclorationSize)

		" Remove end of line comments for multi line...
"	virtual void Test_Member_Function_B1(int _iSomeNumber) = 0;
"	virtual void Test_Member_Function_B1(int _iSomeNumber) = 0; // = 0; yea
"	void Test_Member_Function_F(
"		int _iSomeNumber,				//!< doxy comment
"		char* _cpSomeString,			//!< Same
"		float /*_fNotused*/,		//!< not used param. Heh aka error stress test.
"		int _iFlags = 0			/*!< I think */
"		);	// yea whatever.
"	virtual void Test_Member_Function_B2(int _iSomeNumber/*comment*/, int _iSomeNum2/*some comment*/ = 5);
"	virtual void Test_Member_Function_B2(int _iSomeNumber = 3, int _iSomeNum2 = 5); // yea this is broken currently [Feral:277/02@23:22]

"\/[/*].\{-}$
"\s\{-}\/[/*][^,]\{-}$
"		echo confirm(line('.'))
		let SaveReport = &report
		set report=9999
		let Save2L = line(".")
		execute ':'.Save2L.','.(Save2L+s:LineWithDeclorationSize-1).'s/\s\{-}\/[/*][^,)]\{-}$//e'
		:execute ":normal! ".Save2L."G"
"		echo confirm(line('.'))
		let &report=SaveReport

		" join multi line into one line
		if s:LineWithDeclorationSize > 1
"			echo confirm('Jing '.s:LineWithDeclorationSize.' times...')
			:execute ':normal! '.s:LineWithDeclorationSize.'J'
"			:execute ':join '.s:LineWithDeclorationSize
"			:execute ':'.Save2L.','.(Save2L+s:LineWithDeclorationSize-1).'join '

			" [Feral:278/02@00:17] Get rid of tabs and replace with a single space
			execute ':s/\t\+/ /ge'
			" [Feral:278/02@00:18] Fix up that initial FuncName( param_type param, pt2 param2)
			" I do not like the space between the Function Name the pren and the param.
			execute ':s/\(\i(\) /\1/e'
		endif
		:execute ':normal! =='

		" XXX if you want virtual commented in the implimentation:
		if a:howtoshowVirtual == 1
			execute ':s/\<virtual\>/\/\*&\*\//e'
		else
			" XXX else, remove virtual and any spaces/tabs after it.
			execute ':s/\<virtual\>\s*//e'
		endif

		" XXX if you want static commented in the implimentation:
		if a:howtoshowStatic == 1
			execute ':s/\<static\>/\/\*&\*\//e'
		else
			" XXX else, remove static and any spaces/tabs after it.
			execute ':s/\<static\>\s*//e'
		endif

		" wipe out a pure virtual thingie-ma-bob. (technical term? (= )
"		execute ':s/)\s*=\s*0\s*;/);/e'
		execute ':s/)\s\{-}=\s\{-}0\s\{-};/);/e'

		" Handle default params, if any.
		if a:howtoshowDefaultParams == 1
			" Remove the default param assignments.
			execute ':s/\s\{-}=\s\{-}[^,)]\{1,}//ge'
		else
			" Comment the default param assignments.
			execute ':s/\s\{-}\(=\s\{-}[^,)]\{1,}\)/\/\*\1\*\//ge'

			if a:howtoshowDefaultParams == 3
				" Remove the = and any spaces to the left or right.
				execute ':s/\s*=\s*//ge'
			endif
		endif

		:let @/=@n
		:let @n=Was_Reg_n
		:execute ":normal! ".SaveT."Gzt"
		:execute ":normal! ".SaveL."G"
		:execute ":normal! ".SaveC."|"
		:execute ':normal! f(b'
		if s:ClassName !=# ""
			:execute ':normal! i'.s:ClassName
		endif

		" find the ending ; and replace it with a brace structure on the next line.
"		:execute ":normal! f;s\<cr>{\<cr>}\<cr>\<esc>2k"
		:execute ":normal! f;s\<cr>{\<cr>}\<esc>k"
	endif
endfunc
"}}}

"*****************************************************************
"* Commands
"*****************************************************************
"{{{ Documtation and Command definitions:

" given:
"	virtual void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");

" Prototype:
"GrabFromHeaderPasteInSource(VirtualFlag, StaticFlag, DefaultParamsFlag)

" VirtualFlag:
" 1:	if you want virtual commented in the implimentation:
"	/*virtual*/ void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");
" else:	remove virtual and any spaces/tabs after it.
"	void Test_Member_Function_B3(int _iSomeNum2 = 5, char * _cpStr = "Yea buddy!");

" StaticFlag:
" 1:	if you want static commented in the implimentation:
"	Same as virtual, save deal with static
" else:	remove static and any spaces/tabs after it.
"	Same as virtual, save deal with static

" DefaultParamsFlag:
" 1:	If you want to remove default param reminders, i.e.
"	Test_Member_Function_B3(int _iSomeNum2, char * _cpStr);
" 2:	If you want to comment default param assignments, i.e.
"	Test_Member_Function_B3(int _iSomeNum2/*= 5*/, char * _cpStr/*= "Yea buddy!"*/);
" 3:	Like 2 but, If you do not want the = in the comment, i.e.
"	Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
"
" Examples:
" smallest implimentation:
"	void Test_Member_Function_B3(int _iSomeNum2, char * _cpStr);
":command! -nargs=0 GHPH call <SID>GrabFromHeaderPasteInSource(0,0,1)
"	Verbose...:
"	/*virtual*/ void Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
":command! -nargs=0 GHPH call <SID>GrabFromHeaderPasteInSource(1,1,3)
"	What I like:
"	void Test_Member_Function_B3(int _iSomeNum2/*5*/, char * _cpStr/*"Yea buddy!"*/);
:command! -nargs=0 GHPH call <SID>GrabFromHeaderPasteInSource(0,0,3)

" Bit of trivia... GHPH.. get header, put header. ~shrug~ I needed a
" command name.... (Name it whatever you wish, of course!)

" }}}

" eof
