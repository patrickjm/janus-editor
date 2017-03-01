/*
 * This license does NOT supersede the original license of GPC.  Please see:
 * http://www.cs.man.ac.uk/~toby/alan/software/#Licensing
 *
 * The SEI Software Open Source License, Version 1.0
 *
 * Copyright (c) 2004, Solution Engineering, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. The end-user documentation included with the redistribution,
 *    if any, must include the following acknowledgment:
 *       "This product includes software developed by the
 *        Solution Engineering, Inc. (http://www.seisw.com/)."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 3. The name "Solution Engineering" must not be used to endorse or
 *    promote products derived from this software without prior
 *    written permission. For written permission, please contact
 *    admin@seisw.com.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL SOLUTION ENGINEERING, INC. OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 */

module clipped.clip;

import clipped;
import std.math, std.stdio;

/**
 * <code>Clip</code> is a Java version of the <i>General Poly Clipper</i> algorithm
 * developed by Alan Murta (gpc@cs.man.ac.uk).  The home page for the original source can be 
 * found at <a href="http://www.cs.man.ac.uk/aig/staff/alan/software/" target="_blank">
 * http://www.cs.man.ac.uk/aig/staff/alan/software/</a>.
 * <p>
 * <b><code>polyClass:</code></b> Some of the public methods below take a <code>polyClass</code>
 * argument.  This <code>java.lang.Class</code> object is assumed to implement the <code>Poly</code>
 * interface and have a no argument constructor.  This was done so that the user of the algorithm
 * could create their own classes that implement the <code>Poly</code> interface and still uses
 * this algorithm.
 * <p>
 * <strong>Implementation Note:</strong> The converted algorithm does support the <i>difference</i>
 * operation, but a public method has not been provided and it has not been tested.  To do so,
 * simply follow what has been done for <i>intersection</i>.
 *
 * @author  Dan Bridenbecker, Solution Engineering, Inc.
 */
public class Clip
{
	// -----------------
	// --- Constants ---
	// -----------------
	protected static bool DEBUG = false;
	
	protected static double GPC_EPSILON = 2.2204460492503131e-016;
	//protected static final string GPC_VERSION = "2.31";
	
	protected static int LEFT  = 0;
	protected static int RIGHT = 1;
	
	protected static int ABOVE = 0;
	protected static int BELOW = 1;
	
	protected static int CLIP = 0;
	protected static int SUBJ = 1;

	protected static immutable OT_GPC_DIFF  = OperationType.OT_Difference;
	protected static immutable OT_GPC_INT   = OperationType.OT_Intersection;
	protected static immutable OT_GPC_XOR   = OperationType.OT_ExclusiveOr;
	protected static immutable OT_GPC_UNION = OperationType.OT_Union;
	
	// ------------------------
	// --- Member Variables ---
	// ------------------------
	
	// --------------------
	// --- Constructors ---
	// --------------------
	/** Creates a new instance of Clip */
	protected this()
	{
	}
	
	// ----------------------
	// --- Static Methods ---
	// ----------------------
	/**
	 * Return the intersection of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>polyClass</code>.  See the note in the class description
	 * for more on <ocde>polyClass</code>.
	 *
	 * @param p1        One of the polygons to perform the intersection with
	 * @param p2        One of the polygons to perform the intersection with
	 * @param polyClass The type of <code>Poly</code> to return
	 */
	public static Poly intersection(Poly p1, Poly p2, TypeInfo_Class polyClass)
	{
		return clip(Clip.OT_GPC_INT, p1, p2, polyClass);
	}
	
	/**
	 * Return the union of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>polyClass</code>.  See the note in the class description
	 * for more on <ocde>polyClass</code>.
	 *
	 * @param p1        One of the polygons to perform the union with
	 * @param p2        One of the polygons to perform the union with
	 * @param polyClass The type of <code>Poly</code> to return
	 */
	public static Poly polyUnion(Poly p1, Poly p2, TypeInfo_Class polyClass)
	{
		return clip(Clip.OT_GPC_UNION, p1, p2, polyClass);
	}
	
	/**
	 * Return the xor of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>polyClass</code>.  See the note in the class description
	 * for more on <ocde>polyClass</code>.
	 *
	 * @param p1        One of the polygons to perform the xor with
	 * @param p2        One of the polygons to perform the xor with
	 * @param polyClass The type of <code>Poly</code> to return
	 */
	public static Poly xor(Poly p1, Poly p2, TypeInfo_Class polyClass)
	{
		return clip(Clip.OT_GPC_XOR, p1, p2, polyClass);
	}
	
	/**
	 * Return the difference of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>PolyDefault</code>.
	 * 
	 * @param p1 One of the polygons to perform the difference with
	 * @param p2 One of the polygons to perform the difference with
	 */
	public static Poly difference(Poly p1, Poly p2, TypeInfo_Class polyClass) {
		return clip(Clip.OT_GPC_DIFF, p1, p2, polyClass);
	}
	/**
	 * Return the intersection of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>PolyDefault</code>. 
	 *
	 * @param p1 One of the polygons to perform the intersection with
	 * @param p2 One of the polygons to perform the intersection with
	 */
	public static Poly intersection(Poly p1, Poly p2)
	{
		return clip(Clip.OT_GPC_INT, p1, p2, typeid(PolyDefault));
	}
	
	/**
	 * Return the union of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>PolyDefault</code>. 
	 *
	 * @param p1 One of the polygons to perform the union with
	 * @param p2 One of the polygons to perform the union with
	 */
	public static Poly polyUnion(Poly p1, Poly p2)
	{
		return clip(Clip.OT_GPC_UNION, p1, p2, typeid(PolyDefault));
	}
	
	/**
	 * Return the xor of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>PolyDefault</code>. 
	 *
	 * @param p1 One of the polygons to perform the xor with
	 * @param p2 One of the polygons to perform the xor with
	 */
	public static Poly xor(Poly p1, Poly p2)
	{
		return clip(Clip.OT_GPC_XOR, p1, p2, typeid(PolyDefault));
	}
	
	/**
	 * Return the difference of <code>p1</code> and <code>p2</code> where the
	 * return type is of <code>PolyDefault</code>.
	 * 
	 * @param p1 One of the polygons to perform the difference with
	 * @param p2 One of the polygons to perform the difference with
	 */
	public static Poly difference(Poly p1, Poly p2) {
		return clip(Clip.OT_GPC_DIFF, p1, p2, typeid(PolyDefault));
	}
	
	// -----------------------
	// --- Private Methods ---
	// -----------------------
	
	/**
	 * Create a new <code>Poly</code> type object using <code>polyClass</code>.
	 */
	protected static Poly createNewPoly(TypeInfo_Class polyClass)
	{
		if(polyClass == typeid(PolyDefault))
		{
			return new PolyDefault();
		}
		else if (polyClass == typeid(PolySimple))
		{
			return new PolySimple();
		}
		assert(0, "Nope");
	}
	
	/**
	 * <code>clip()</code> is the main method of the clipper algorithm.
	 * This is where the conversion from really begins.
	 */
	protected static Poly clip(OperationType op, Poly subj, Poly clip, TypeInfo_Class polyClass)
	{
		Poly result = createNewPoly(polyClass);
		
		/* Test for trivial NULL result cases */
		if((subj.isEmpty() && clip.isEmpty()) ||
		   (subj.isEmpty() && ((op == Clip.OT_GPC_INT) || (op == Clip.OT_GPC_DIFF))) ||
		   (clip.isEmpty() &&  (op == Clip.OT_GPC_INT)))
		{
			return result;
		}
		
		/* Identify potentially contributing contours */
		if(((op == Clip.OT_GPC_INT) || (op == Clip.OT_GPC_DIFF)) && 
		   !subj.isEmpty() && !clip.isEmpty())
		{
			minimax_test(subj, clip, op);
		}
		
		/* Build LMT */
		LmtTable lmt_table = new LmtTable();
		ScanBeamTreeEntries sbte = new ScanBeamTreeEntries();
		if (!subj.isEmpty())
		{
			build_lmt(lmt_table, sbte, subj, Clip.SUBJ, op);
		}
		if (!clip.isEmpty())
		{
			build_lmt(lmt_table, sbte, clip, Clip.CLIP, op);
		}
		
		/* Return a NULL result if no contours contribute */
		if (lmt_table.top_node is null)
		{
			return result;
		}
		
		/* Build scanbeam table from scanbeam tree */
		double[] sbt = sbte.build_sbt();
		
		int[] parity = [Clip.LEFT, Clip.LEFT];
		
		/* Invert clip polygon for difference operation */
		if (op == Clip.OT_GPC_DIFF)
		{
			parity[Clip.CLIP]= Clip.RIGHT;
		}
		
		LmtNode local_min = lmt_table.top_node;
		
		TopPolygonNode out_poly = new TopPolygonNode(); // used to create resulting Poly
		
		AetTree aet = new AetTree();
		int scanbeam = 0;
		
		/* Process each scanbeam */
		while(scanbeam < sbt.length)
		{
			/* Set yb and yt to the bottom and top of the scanbeam */
			double yb = sbt[scanbeam++];
			double yt = 0.0;
			double dy = 0.0;
			if(scanbeam < sbt.length)
			{
				yt = sbt[scanbeam];
				dy = yt - yb;
			}
			
			/* === SCANBEAM BOUNDARY PROCESSING ================================ */
			
			/* If LMT node corresponding to yb exists */
			if (local_min !is null)
			{
				if (local_min.y == yb)
				{
					/* Add edges starting at this local minimum to the AET */
					for(EdgeNode edge = local_min.first_bound; (edge !is null); edge= edge.next_bound)
					{
						add_edge_to_aet(aet, edge);
					}
					
					local_min = local_min.next;
				}
			}
			
			/* Set dummy previous x value */
			double px = -double.max;
			
			/* Create bundles within AET */
			EdgeNode e0 = aet.top_node;
			EdgeNode e1 = aet.top_node;
			
			/* Set up bundle fields of first edge */
			aet.top_node.bundle[Clip.ABOVE][aet.top_node.type] = (aet.top_node.top.y != yb) ? 1 : 0;
			aet.top_node.bundle[Clip.ABOVE][((aet.top_node.type==0) ? 1 : 0)] = 0;
			aet.top_node.bstate[Clip.ABOVE] = BundleState.UNBUNDLED;
			
			for (EdgeNode next_edge= aet.top_node.next; (next_edge !is null); next_edge = next_edge.next)
			{
				int ne_type = next_edge.type;
				int ne_type_opp = ((next_edge.type==0) ? 1 : 0); //next edge type opposite
				
				/* Set up bundle fields of next edge */
				next_edge.bundle[Clip.ABOVE][ne_type    ]= (next_edge.top.y != yb) ? 1 : 0;
				next_edge.bundle[Clip.ABOVE][ne_type_opp] = 0;
				next_edge.bstate[Clip.ABOVE] = BundleState.UNBUNDLED;
				
				/* Bundle edges above the scanbeam boundary if they coincide */
				if (next_edge.bundle[Clip.ABOVE][ne_type] == 1)
				{
					if (EQ(e0.xb, next_edge.xb) && EQ(e0.dx, next_edge.dx) && (e0.top.y != yb))
					{
						next_edge.bundle[Clip.ABOVE][ne_type    ] ^= e0.bundle[Clip.ABOVE][ne_type    ];
						next_edge.bundle[Clip.ABOVE][ne_type_opp]  = e0.bundle[Clip.ABOVE][ne_type_opp];
						next_edge.bstate[Clip.ABOVE] = BundleState.BUNDLE_HEAD;
						e0.bundle[Clip.ABOVE][Clip.CLIP] = 0;
						e0.bundle[Clip.ABOVE][Clip.SUBJ] = 0;
						e0.bstate[Clip.ABOVE] = BundleState.BUNDLE_TAIL;
					}
					e0 = next_edge;
				}
			}
			
			int[] horiz = [0, 0];
			horiz[Clip.CLIP]= HState.NH;
			horiz[Clip.SUBJ]= HState.NH;
			
			int[] exists = [0, 0];
			exists[Clip.CLIP] = 0;
			exists[Clip.SUBJ] = 0;
			
			PolygonNode cf = null;
			
			/* Process each edge at this scanbeam boundary */
			for (EdgeNode edge= aet.top_node; (edge !is null); edge = edge.next)
			{
				exists[Clip.CLIP] = edge.bundle[Clip.ABOVE][Clip.CLIP] + (edge.bundle[Clip.BELOW][Clip.CLIP] << 1);
				exists[Clip.SUBJ] = edge.bundle[Clip.ABOVE][Clip.SUBJ] + (edge.bundle[Clip.BELOW][Clip.SUBJ] << 1);
				
				if((exists[Clip.CLIP] != 0) || (exists[Clip.SUBJ] != 0))
				{
					/* Set bundle side */
					edge.bside[Clip.CLIP] = parity[Clip.CLIP];
					edge.bside[Clip.SUBJ] = parity[Clip.SUBJ];
					
					bool contributing = false;
					int br=0, bl=0, tr=0, tl=0;
					/* Determine contributing status and quadrant occupancies */
					if((op == Clip.OT_GPC_DIFF) || (op == Clip.OT_GPC_INT))
					{
						contributing= ((exists[Clip.CLIP]!=0) && ((parity[Clip.SUBJ]!=0) || (horiz[Clip.SUBJ]!=0))) ||
							((exists[Clip.SUBJ]!=0) && ((parity[Clip.CLIP]!=0) || (horiz[Clip.CLIP]!=0))) ||
								((exists[Clip.CLIP]!=0) && (exists[Clip.SUBJ]!=0) && (parity[Clip.CLIP] == parity[Clip.SUBJ]));
						br = ((parity[Clip.CLIP]!=0) && (parity[Clip.SUBJ]!=0)) ? 1 : 0;
						bl = (((parity[Clip.CLIP] ^ edge.bundle[Clip.ABOVE][Clip.CLIP])!=0) &&
						      ((parity[Clip.SUBJ] ^ edge.bundle[Clip.ABOVE][Clip.SUBJ])!=0)) ? 1 : 0;
						tr = (((parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0)) !=0) && 
						      ((parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0)) !=0)) ? 1 : 0;
						tl = (((parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.CLIP])!=0) &&
						      ((parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.SUBJ])!=0))?1:0;
					}
					else if(op == Clip.OT_GPC_XOR)
					{
						contributing= (exists[Clip.CLIP]!=0) || (exists[Clip.SUBJ]!=0);
						br= (parity[Clip.CLIP]) ^ (parity[Clip.SUBJ]);
						bl= (parity[Clip.CLIP] ^ edge.bundle[Clip.ABOVE][Clip.CLIP]) ^ (parity[Clip.SUBJ] ^ edge.bundle[Clip.ABOVE][Clip.SUBJ]);
						tr= (parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0)) ^ (parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0));
						tl= (parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.CLIP])
							^ (parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.SUBJ]);
					}
					else if(op == Clip.OT_GPC_UNION)
					{
						contributing= ((exists[Clip.CLIP]!=0) && (!(parity[Clip.SUBJ]!=0) || (horiz[Clip.SUBJ]!=0))) ||
							((exists[Clip.SUBJ]!=0) && (!(parity[Clip.CLIP]!=0) || (horiz[Clip.CLIP]!=0))) ||
								((exists[Clip.CLIP]!=0) && (exists[Clip.SUBJ]!=0) && (parity[Clip.CLIP] == parity[Clip.SUBJ]));
						br= ((parity[Clip.CLIP]!=0) || (parity[Clip.SUBJ]!=0))?1:0;
						bl= (((parity[Clip.CLIP] ^ edge.bundle[Clip.ABOVE][Clip.CLIP])!=0) || ((parity[Clip.SUBJ] ^ edge.bundle[Clip.ABOVE][Clip.SUBJ])!=0))?1:0;
						tr= (((parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0))!=0) || 
						     ((parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0))!=0)) ?1:0;
						tl= (((parity[Clip.CLIP] ^ ((horiz[Clip.CLIP]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.CLIP])!=0) ||
						     ((parity[Clip.SUBJ] ^ ((horiz[Clip.SUBJ]!=HState.NH)?1:0) ^ edge.bundle[Clip.BELOW][Clip.SUBJ])!=0)) ? 1:0;
					}
					else
					{
						assert(0, "Unknown op");
					}
					
					/* Update parity */
					parity[Clip.CLIP] ^= edge.bundle[Clip.ABOVE][Clip.CLIP];
					parity[Clip.SUBJ] ^= edge.bundle[Clip.ABOVE][Clip.SUBJ];
					
					/* Update horizontal state */
					if (exists[Clip.CLIP]!=0)
					{
						horiz[Clip.CLIP] = HState.next_h_state[horiz[Clip.CLIP]][((exists[Clip.CLIP] - 1) << 1) + parity[Clip.CLIP]];
					}
					if(exists[Clip.SUBJ]!=0)
					{
						horiz[Clip.SUBJ] = HState.next_h_state[horiz[Clip.SUBJ]][((exists[Clip.SUBJ] - 1) << 1) + parity[Clip.SUBJ]];
					}
					
					if (contributing)
					{
						double xb = edge.xb;
						
						int vclass = VertexType.getType(tr, tl, br, bl);
						switch (vclass)
						{
							case VertexType.EMN:
							case VertexType.IMN:
								edge.outp[Clip.ABOVE] = out_poly.add_local_min(xb, yb);
								px = xb;
								cf = edge.outp[Clip.ABOVE];
								break;
							case VertexType.ERI:
								if (xb != px)
								{
									cf.add_right(xb, yb);
									px= xb;
								}
								edge.outp[Clip.ABOVE]= cf;
								cf= null;
								break;
							case VertexType.ELI:
								edge.outp[Clip.BELOW].add_left(xb, yb);
								px= xb;
								cf= edge.outp[Clip.BELOW];
								break;
							case VertexType.EMX:
								if (xb != px)
								{
									cf.add_left(xb, yb);
									px= xb;
								}
								out_poly.merge_right(cf, edge.outp[Clip.BELOW]);
								cf= null;
								break;
							case VertexType.ILI:
								if (xb != px)
								{
									cf.add_left(xb, yb);
									px= xb;
								}
								edge.outp[Clip.ABOVE]= cf;
								cf= null;
								break;
							case VertexType.IRI:
								edge.outp[Clip.BELOW].add_right(xb, yb);
								px= xb;
								cf= edge.outp[Clip.BELOW];
								edge.outp[Clip.BELOW]= null;
								break;
							case VertexType.IMX:
								if (xb != px)
								{
									cf.add_right(xb, yb);
									px= xb;
								}
								out_poly.merge_left(cf, edge.outp[Clip.BELOW]);
								cf= null;
								edge.outp[Clip.BELOW]= null;
								break;
							case VertexType.IMM:
								if (xb != px)
								{
									cf.add_right(xb, yb);
									px= xb;
								}
								out_poly.merge_left(cf, edge.outp[Clip.BELOW]);
								edge.outp[Clip.BELOW]= null;
								edge.outp[Clip.ABOVE] = out_poly.add_local_min(xb, yb);
								cf= edge.outp[Clip.ABOVE];
								break;
							case VertexType.EMM:
								if (xb != px)
								{
									cf.add_left(xb, yb);
									px= xb;
								}
								out_poly.merge_right(cf, edge.outp[Clip.BELOW]);
								edge.outp[Clip.BELOW]= null;
								edge.outp[Clip.ABOVE] = out_poly.add_local_min(xb, yb);
								cf= edge.outp[Clip.ABOVE];
								break;
							case VertexType.LED:
								if (edge.bot.y == yb)
									edge.outp[Clip.BELOW].add_left(xb, yb);
								edge.outp[Clip.ABOVE]= edge.outp[Clip.BELOW];
								px= xb;
								break;
							case VertexType.RED:
								if (edge.bot.y == yb)
									edge.outp[Clip.BELOW].add_right(xb, yb);
								edge.outp[Clip.ABOVE]= edge.outp[Clip.BELOW];
								px= xb;
								break;
							default:
								break;
						} /* End of switch */
					} /* End of contributing conditional */
				} /* End of edge exists conditional */
			} /* End of AET loop */
			
			/* Delete terminating edges from the AET, otherwise compute xt */
			for (EdgeNode edge = aet.top_node; (edge !is null); edge = edge.next)
			{
				if (edge.top.y == yb)
				{
					EdgeNode prev_edge = edge.prev;
					EdgeNode next_edge= edge.next;
					
					if (prev_edge !is null)
						prev_edge.next = next_edge;
					else
						aet.top_node = next_edge;
					
					if (next_edge !is null)
						next_edge.prev = prev_edge;
					
					/* Copy bundle head state to the adjacent tail edge if required */
					if ((edge.bstate[Clip.BELOW] == BundleState.BUNDLE_HEAD) && (prev_edge !is null))
					{
						if (prev_edge.bstate[Clip.BELOW] == BundleState.BUNDLE_TAIL)
						{
							prev_edge.outp[Clip.BELOW]= edge.outp[Clip.BELOW];
							prev_edge.bstate[Clip.BELOW]= BundleState.UNBUNDLED;
							if (prev_edge.prev !is null)
							{
								if (prev_edge.prev.bstate[Clip.BELOW] == BundleState.BUNDLE_TAIL)
								{
									prev_edge.bstate[Clip.BELOW] = BundleState.BUNDLE_HEAD;
								}
							}
						}
					}
				}
				else
				{
					if (edge.top.y == yt)
						edge.xt= edge.top.x;
					else
						edge.xt= edge.bot.x + edge.dx * (yt - edge.bot.y);
				}
			}
			
			if (scanbeam < sbte.sbt_entries)
			{
				/* === SCANBEAM INTERIOR PROCESSING ============================== */
				
				/* Build intersection table for the current scanbeam */
				ItNodeTable it_table = new ItNodeTable();
				it_table.build_intersection_table(aet, dy);
				
				/* Process each node in the intersection table */
				for (ItNode intersect = it_table.top_node; (intersect !is null); intersect = intersect.next)
				{
					e0= intersect.ie[0];
					e1= intersect.ie[1];
					
					/* Only generate output for contributing intersections */
					if (((e0.bundle[Clip.ABOVE][Clip.CLIP]!=0) || (e0.bundle[Clip.ABOVE][Clip.SUBJ]!=0)) &&
					    ((e1.bundle[Clip.ABOVE][Clip.CLIP]!=0) || (e1.bundle[Clip.ABOVE][Clip.SUBJ]!=0)))
					{
						PolygonNode p = e0.outp[Clip.ABOVE];
						PolygonNode q = e1.outp[Clip.ABOVE];
						double ix = intersect.point.x;
						double iy = intersect.point.y + yb;
						
						int in_clip = (((e0.bundle[Clip.ABOVE][Clip.CLIP]!=0) && !(e0.bside[Clip.CLIP]!=0)) ||
						               ((e1.bundle[Clip.ABOVE][Clip.CLIP]!=0) &&  (e1.bside[Clip.CLIP]!=0)) ||
						               (!(e0.bundle[Clip.ABOVE][Clip.CLIP]!=0) && !(e1.bundle[Clip.ABOVE][Clip.CLIP]!=0) &&
						 (e0.bside[Clip.CLIP]!=0) && (e1.bside[Clip.CLIP]!=0))) ? 1 : 0;
						
						int in_subj = (((e0.bundle[Clip.ABOVE][Clip.SUBJ]!=0) && !(e0.bside[Clip.SUBJ]!=0)) ||
						               ((e1.bundle[Clip.ABOVE][Clip.SUBJ]!=0) &&  (e1.bside[Clip.SUBJ]!=0)) ||
						               (!(e0.bundle[Clip.ABOVE][Clip.SUBJ]!=0) && !(e1.bundle[Clip.ABOVE][Clip.SUBJ]!=0) &&
						 (e0.bside[Clip.SUBJ]!=0) && (e1.bside[Clip.SUBJ]!=0))) ? 1 : 0;
						
						int tr=0, tl=0, br=0, bl=0;
						/* Determine quadrant occupancies */
						if((op == Clip.OT_GPC_DIFF) || (op == Clip.OT_GPC_INT))
						{
							tr= ((in_clip!=0) && (in_subj!=0)) ? 1 : 0;
							tl= (((in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP])!=0) && ((in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ])!=0))?1:0;
							br= (((in_clip ^ e0.bundle[Clip.ABOVE][Clip.CLIP])!=0) && ((in_subj ^ e0.bundle[Clip.ABOVE][Clip.SUBJ])!=0))?1:0;
							bl= (((in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP] ^ e0.bundle[Clip.ABOVE][Clip.CLIP])!=0) &&
							     ((in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ] ^ e0.bundle[Clip.ABOVE][Clip.SUBJ])!=0)) ? 1:0;
						}
						else if(op == Clip.OT_GPC_XOR)
						{
							tr= (in_clip)^ (in_subj);
							tl= (in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP]) ^ (in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ]);
							br= (in_clip ^ e0.bundle[Clip.ABOVE][Clip.CLIP]) ^ (in_subj ^ e0.bundle[Clip.ABOVE][Clip.SUBJ]);
							bl= (in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP] ^ e0.bundle[Clip.ABOVE][Clip.CLIP])
								^ (in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ] ^ e0.bundle[Clip.ABOVE][Clip.SUBJ]);
						}
						else if(op == Clip.OT_GPC_UNION)
						{
							tr= ((in_clip!=0) || (in_subj!=0)) ? 1 : 0;
							tl= (((in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP])!=0) || ((in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ])!=0)) ? 1 : 0;
							br= (((in_clip ^ e0.bundle[Clip.ABOVE][Clip.CLIP])!=0) || ((in_subj ^ e0.bundle[Clip.ABOVE][Clip.SUBJ])!=0)) ? 1 : 0;
							bl= (((in_clip ^ e1.bundle[Clip.ABOVE][Clip.CLIP] ^ e0.bundle[Clip.ABOVE][Clip.CLIP])!=0) ||
							     ((in_subj ^ e1.bundle[Clip.ABOVE][Clip.SUBJ] ^ e0.bundle[Clip.ABOVE][Clip.SUBJ])!=0)) ? 1 : 0;
						}
						else
						{
							import std.conv;
							assert(0, "Unknown op type, " ~ to!string(op));
						}
						
						int vclass = VertexType.getType(tr, tl, br, bl);
						switch (vclass)
						{
							case VertexType.EMN:
								e0.outp[Clip.ABOVE] = out_poly.add_local_min(ix, iy);
								e1.outp[Clip.ABOVE] = e0.outp[Clip.ABOVE];
								break;
							case VertexType.ERI:
								if (p !is null)
								{
									p.add_right(ix, iy);
									e1.outp[Clip.ABOVE]= p;
									e0.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.ELI:
								if (q !is null)
								{
									q.add_left(ix, iy);
									e0.outp[Clip.ABOVE]= q;
									e1.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.EMX:
								if ((p !is null) && (q !is null))
								{
									p.add_left(ix, iy);
									out_poly.merge_right(p, q);
									e0.outp[Clip.ABOVE]= null;
									e1.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.IMN:
								e0.outp[Clip.ABOVE] = out_poly.add_local_min(ix, iy);
								e1.outp[Clip.ABOVE]= e0.outp[Clip.ABOVE];
								break;
							case VertexType.ILI:
								if (p !is null)
								{
									p.add_left(ix, iy);
									e1.outp[Clip.ABOVE]= p;
									e0.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.IRI:
								if (q !is null)
								{
									q.add_right(ix, iy);
									e0.outp[Clip.ABOVE]= q;
									e1.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.IMX:
								if ((p !is null) && (q !is null))
								{
									p.add_right(ix, iy);
									out_poly.merge_left(p, q);
									e0.outp[Clip.ABOVE]= null;
									e1.outp[Clip.ABOVE]= null;
								}
								break;
							case VertexType.IMM:
								if ((p !is null) && (q !is null))
								{
									p.add_right(ix, iy);
									out_poly.merge_left(p, q);
									e0.outp[Clip.ABOVE] = out_poly.add_local_min(ix, iy);
									e1.outp[Clip.ABOVE]= e0.outp[Clip.ABOVE];
								}
								break;
							case VertexType.EMM:
								if ((p !is null) && (q !is null))
								{
									p.add_left(ix, iy);
									out_poly.merge_right(p, q);
									e0.outp[Clip.ABOVE] = out_poly.add_local_min(ix, iy);
									e1.outp[Clip.ABOVE] = e0.outp[Clip.ABOVE];
								}
								break;
							default:
								break;
						} /* End of switch */
					} /* End of contributing intersection conditional */                  
					
					/* Swap bundle sides in response to edge crossing */
					if (e0.bundle[Clip.ABOVE][Clip.CLIP]!=0)
						e1.bside[Clip.CLIP] = (e1.bside[Clip.CLIP]==0)?1:0;
					if (e1.bundle[Clip.ABOVE][Clip.CLIP]!=0)
						e0.bside[Clip.CLIP]= (e0.bside[Clip.CLIP]==0)?1:0;
					if (e0.bundle[Clip.ABOVE][Clip.SUBJ]!=0)
						e1.bside[Clip.SUBJ]= (e1.bside[Clip.SUBJ]==0)?1:0;
					if (e1.bundle[Clip.ABOVE][Clip.SUBJ]!=0)
						e0.bside[Clip.SUBJ]= (e0.bside[Clip.SUBJ]==0)?1:0;
					
					/* Swap e0 and e1 bundles in the AET */
					EdgeNode prev_edge = e0.prev;
					EdgeNode next_edge = e1.next;
					if (next_edge !is null)
					{
						next_edge.prev = e0;
					}
					
					if (e0.bstate[Clip.ABOVE] == BundleState.BUNDLE_HEAD)
					{
						bool search = true;
						while (search)
						{
							prev_edge= prev_edge.prev;
							if (prev_edge !is null)
							{
								if (prev_edge.bstate[Clip.ABOVE] != BundleState.BUNDLE_TAIL)
								{
									search= false;
								}
							}
							else
							{
								search= false;
							}
						}
					}
					if (prev_edge is null)
					{
						aet.top_node.prev = e1;
						e1.next           = aet.top_node;
						aet.top_node      = e0.next;
					}
					else
					{
						prev_edge.next.prev = e1;
						e1.next             = prev_edge.next;
						prev_edge.next      = e0.next;
					}
					e0.next.prev = prev_edge;
					e1.next.prev = e1;
					e0.next      = next_edge;
				} /* End of IT loop*/
				
				/* Prepare for next scanbeam */
				for (EdgeNode edge = aet.top_node; (edge !is null); edge = edge.next)
				{
					EdgeNode next_edge = edge.next;
					EdgeNode succ_edge = edge.succ;
					if ((edge.top.y == yt) && (succ_edge !is null))
					{
						/* Replace AET edge by its successor */
						succ_edge.outp[Clip.BELOW]= edge.outp[Clip.ABOVE];
						succ_edge.bstate[Clip.BELOW]= edge.bstate[Clip.ABOVE];
						succ_edge.bundle[Clip.BELOW][Clip.CLIP]= edge.bundle[Clip.ABOVE][Clip.CLIP];
						succ_edge.bundle[Clip.BELOW][Clip.SUBJ]= edge.bundle[Clip.ABOVE][Clip.SUBJ];
						EdgeNode prev_edge = edge.prev;
						if (prev_edge !is null)
							prev_edge.next = succ_edge;
						else
							aet.top_node = succ_edge;
						if (next_edge !is null)
							next_edge.prev= succ_edge;
						succ_edge.prev = prev_edge;
						succ_edge.next = next_edge;
					}
					else
					{
						/* Update this edge */
						edge.outp[Clip.BELOW]= edge.outp[Clip.ABOVE];
						edge.bstate[Clip.BELOW]= edge.bstate[Clip.ABOVE];
						edge.bundle[Clip.BELOW][Clip.CLIP]= edge.bundle[Clip.ABOVE][Clip.CLIP];
						edge.bundle[Clip.BELOW][Clip.SUBJ]= edge.bundle[Clip.ABOVE][Clip.SUBJ];
						edge.xb= edge.xt;
					}
					edge.outp[Clip.ABOVE]= null;
				}
			}
		} /* === END OF SCANBEAM PROCESSING ================================== */
		
		/* Generate result polygon from out_poly */
		result = out_poly.getResult(polyClass);
		
		return result;
	}
	
	protected static bool EQ(double a, double b)
	{
		return (abs(a - b) <= GPC_EPSILON);
	}
	
	protected static int PREV_INDEX(int i, int n)
	{
		return ((i - 1 + n) % n);
	}
	
	protected static int NEXT_INDEX(int i, int n)
	{
		return ((i + 1   ) % n);
	}
	
	protected static bool OPTIMAL(Poly p, int i)
	{
		return (p.getY(PREV_INDEX(i, p.getNumPoints())) != p.getY(i)) || 
			(p.getY(NEXT_INDEX(i, p.getNumPoints())) != p.getY(i));
	}
	
	protected static Rectangle2D[] create_contour_bboxes(Poly p)
	{
		Rectangle2D[] box = [];
		box.length = p.getNumInnerPoly();
		
		/* Construct contour bounding boxes */
		for (int c= 0; c < p.getNumInnerPoly(); c++)
		{
			Poly inner_poly = p.getInnerPoly(c);
			box[c] = inner_poly.getBounds();
		}
		return box;  
	}
	
	protected static void minimax_test(Poly subj, Poly clip, OperationType op)
	{
		Rectangle2D[] s_bbox = create_contour_bboxes(subj);
		Rectangle2D[] c_bbox = create_contour_bboxes(clip);
		
		int subj_num_poly = subj.getNumInnerPoly();
		int clip_num_poly = clip.getNumInnerPoly();
		//bool[][] o_table = new bool[subj_num_poly][clip_num_poly];
		bool[][] o_table = [];
		o_table.length = subj_num_poly;
		for(int i = 0; i < subj_num_poly; i++)
		{
			bool[] addon = [];
			addon.length = clip_num_poly;
			o_table[i] = addon;
		}
		
		/* Check all subject contour bounding boxes against clip boxes */
		for(int s = 0; s < subj_num_poly; s++)
		{
			for(int c = 0; c < clip_num_poly; c++)
			{
				o_table[s][c] =
					(!((s_bbox[s].getMaxX() < c_bbox[c].getMinX()) ||
					   (s_bbox[s].getMinX() > c_bbox[c].getMaxX()))) &&
						(!((s_bbox[s].getMaxY() < c_bbox[c].getMinY()) ||
						   (s_bbox[s].getMinY() > c_bbox[c].getMaxY())));
			}
		}
		
		/* For each clip contour, search for any subject contour overlaps */
		for(int c = 0; c < clip_num_poly; c++)
		{
			bool overlap = false;
			for(int s = 0; !overlap && (s < subj_num_poly); s++)
			{
				overlap = o_table[s][c];
			}
			if (!overlap)
			{
				clip.setContributing(c, false); // Flag non contributing status
			}
		}  
		
		if (op == Clip.OT_GPC_INT)
		{  
			/* For each subject contour, search for any clip contour overlaps */
			for (int s= 0; s < subj_num_poly; s++)
			{
				bool overlap = false;
				for (int c= 0; !overlap && (c < clip_num_poly); c++)
				{
					overlap = o_table[s][c];
				}
				if (!overlap)
				{
					subj.setContributing(s, false); // Flag non contributing status
				}
			}  
		}
	}
	
	protected static LmtNode bound_list(LmtTable lmt_table, double y)
	{
		if(lmt_table.top_node is null)
		{
			lmt_table.top_node = new LmtNode(y);
			return lmt_table.top_node;
		}
		else
		{
			LmtNode prev = null;
			LmtNode node = lmt_table.top_node;
			bool done = false;
			while(!done)
			{
				if(y < node.y)
				{
					/* Insert a new LMT node before the current node */
					LmtNode existing_node = node;
					node = new LmtNode(y);
					node.next = existing_node;
					if(prev is null)
					{
						lmt_table.top_node = node;
					}
					else
					{
						prev.next = node;
					}
					done = true;
				}
				else if (y > node.y)
				{
					/* Head further up the LMT */
					if(node.next is null)
					{
						node.next = new LmtNode(y);
						node = node.next;
						done = true;
					}
					else
					{
						prev = node;
						node = node.next;
					}
				}
				else
				{
					/* Use this existing LMT node */
					done = true;
				}
			}
			return node;
		}
	}
	
	protected static void insert_bound(LmtNode lmt_node, EdgeNode e)
	{
		if(lmt_node.first_bound is null)
		{
			/* Link node e to the tail of the list */
			lmt_node.first_bound = e;
		}
		else
		{
			bool done = false;
			EdgeNode prev_bound = null;
			EdgeNode current_bound = lmt_node.first_bound;
			while(!done)
			{
				/* Do primary sort on the x field */
				if (e.bot.x <  current_bound.bot.x)
				{
					/* Insert a new node mid-list */
					if(prev_bound is null)
					{
						lmt_node.first_bound = e;
					}
					else
					{
						prev_bound.next_bound = e;
					}
					e.next_bound = current_bound;
					
					done = true;
				}
				else if (e.bot.x == current_bound.bot.x)
				{
					/* Do secondary sort on the dx field */
					if (e.dx < current_bound.dx)
					{
						/* Insert a new node mid-list */
						if(prev_bound is null)
						{
							lmt_node.first_bound = e;
						}
						else
						{
							prev_bound.next_bound = e;
						}
						e.next_bound = current_bound;
						done = true;
					}
					else
					{
						/* Head further down the list */
						if(current_bound.next_bound is null)
						{
							current_bound.next_bound = e;
							done = true;
						}
						else
						{
							prev_bound = current_bound;
							current_bound = current_bound.next_bound;
						}
					}
				}
				else
				{
					/* Head further down the list */
					if(current_bound.next_bound is null)
					{
						current_bound.next_bound = e;
						done = true;
					}
					else
					{
						prev_bound = current_bound;
						current_bound = current_bound.next_bound;
					}
				}
			}
		}
	}
	
	protected static void add_edge_to_aet(AetTree aet , EdgeNode edge)
	{
		if (aet.top_node is null)
		{
			/* Append edge onto the tail end of the AET */
			aet.top_node = edge;
			edge.prev = null;
			edge.next= null;
		}
		else
		{
			EdgeNode current_edge = aet.top_node;
			EdgeNode prev = null;
			bool done = false;
			while(!done)
			{
				/* Do primary sort on the xb field */
				if (edge.xb < current_edge.xb)
				{
					/* Insert edge here (before the AET edge) */
					edge.prev= prev;
					edge.next= current_edge;
					current_edge.prev = edge;
					if(prev is null)
					{
						aet.top_node = edge;
					}
					else
					{
						prev.next = edge;
					}
					done = true;
				}
				else if (edge.xb == current_edge.xb)
				{
					/* Do secondary sort on the dx field */
					if (edge.dx < current_edge.dx)
					{
						/* Insert edge here (before the AET edge) */
						edge.prev= prev;
						edge.next= current_edge;
						current_edge.prev = edge;
						if(prev is null)
						{
							aet.top_node = edge;
						}
						else
						{
							prev.next = edge;
						}
						done = true;
					}
					else
					{
						/* Head further into the AET */
						prev = current_edge;
						if(current_edge.next is null)
						{
							current_edge.next = edge;
							edge.prev = current_edge;
							edge.next = null;
							done = true;
						}
						else
						{
							current_edge = current_edge.next;
						}
					}
				}
				else
				{
					/* Head further into the AET */
					prev = current_edge;
					if(current_edge.next is null)
					{
						current_edge.next = edge;
						edge.prev = current_edge;
						edge.next = null;
						done = true;
					}
					else
					{
						current_edge = current_edge.next;
					}
				}
			}
		}
	}
	
	protected static void add_to_sbtree(ScanBeamTreeEntries sbte, double y)
	{
		if(sbte.sb_tree is null)
		{
			/* Add a new tree node here */
			sbte.sb_tree = new ScanBeamTree(y);
			sbte.sbt_entries++;
			return;
		}
		ScanBeamTree tree_node = sbte.sb_tree;
		bool done = false;
		while(!done)
		{
			if (tree_node.y > y)
			{
				if(tree_node.less is null)
				{
					tree_node.less = new ScanBeamTree(y);
					sbte.sbt_entries++;
					done = true;
				}
				else
				{
					tree_node = tree_node.less;
				}
			}
			else if (tree_node.y < y)
			{
				if(tree_node.more is null)
				{
					tree_node.more = new ScanBeamTree(y);
					sbte.sbt_entries++;
					done = true;
				}
				else
				{
					tree_node = tree_node.more;
				}
			}
			else
			{
				done = true;
			}
		}
	}
	
	protected static EdgeTable build_lmt(LmtTable lmt_table, 
	                                   ScanBeamTreeEntries sbte,
	                                   Poly p, 
	                                   int type, //poly type Clip.SUBJ/Clip.CLIP
	                                   OperationType op)
	{
		/* Create the entire input polygon edge table in one go */
		EdgeTable edge_table = new EdgeTable();
		
		for (int c= 0; c < p.getNumInnerPoly(); c++)
		{
			Poly ip = p.getInnerPoly(c);
			if(!ip.isContributing(0))
			{
				/* Ignore the non-contributing contour */
				ip.setContributing(0, true);
			}
			else
			{
				/* Perform contour optimisation */
				int num_vertices= 0;
				int e_index = 0;
				edge_table = new EdgeTable();
				for (int i= 0; i < ip.getNumPoints(); i++)
				{
					if(OPTIMAL(ip, i))
					{
						double x = ip.getX(i);
						double y = ip.getY(i);
						edge_table.addNode(x, y);
						
						/* Record vertex in the scanbeam table */
						add_to_sbtree(sbte, ip.getY(i));
						
						num_vertices++;
					}
				}
				
				/* Do the contour forward pass */
				for (int min= 0; min < num_vertices; min++)
				{
					/* If a forward local minimum... */
					if(edge_table.FWD_MIN(min))
					{
						/* Search for the next local maximum... */
						int num_edges = 1;
						int max = NEXT_INDEX(min, num_vertices);
						while(edge_table.NOT_FMAX(max))
						{
							num_edges++;
							max = NEXT_INDEX(max, num_vertices);
						}
						
						/* Build the next edge list */
						int v = min;
						EdgeNode e = edge_table.getNode(e_index);
						e.bstate[Clip.BELOW] = BundleState.UNBUNDLED;
						e.bundle[Clip.BELOW][Clip.CLIP] = 0;
						e.bundle[Clip.BELOW][Clip.SUBJ] = 0;
						
						for (int i= 0; i < num_edges; i++)
						{
							EdgeNode ei = edge_table.getNode(e_index+i);
							EdgeNode ev = edge_table.getNode(v);
							
							ei.xb    = ev.vertex.x;
							ei.bot.x = ev.vertex.x;
							ei.bot.y = ev.vertex.y;
							
							v = NEXT_INDEX(v, num_vertices);
							ev = edge_table.getNode(v);
							
							ei.top.x= ev.vertex.x;
							ei.top.y= ev.vertex.y;
							ei.dx= (ev.vertex.x - ei.bot.x) / (ei.top.y - ei.bot.y);
							ei.type = type;
							ei.outp[Clip.ABOVE] = null;
							ei.outp[Clip.BELOW] = null;
							ei.next = null;
							ei.prev = null;
							ei.succ = ((num_edges > 1) && (i < (num_edges - 1))) ? edge_table.getNode(e_index+i+1) : null;
							ei.next_bound = null;
							ei.bside[Clip.CLIP] = (op == Clip.OT_GPC_DIFF) ? Clip.RIGHT : Clip.LEFT;
							ei.bside[Clip.SUBJ] = Clip.LEFT;
						}
						insert_bound(bound_list(lmt_table, edge_table.getNode(min).vertex.y), e);
						e_index += num_edges;
					}
				}
				
				/* Do the contour reverse pass */
				for (int min= 0; min < num_vertices; min++)
				{
					/* If a reverse local minimum... */
					if (edge_table.REV_MIN(min))
					{
						/* Search for the previous local maximum... */
						int num_edges= 1;
						int max = PREV_INDEX(min, num_vertices);
						while(edge_table.NOT_RMAX(max))
						{
							num_edges++;
							max = PREV_INDEX(max, num_vertices);
						}
						
						/* Build the previous edge list */
						int v = min;
						EdgeNode e = edge_table.getNode(e_index);
						e.bstate[Clip.BELOW] = BundleState.UNBUNDLED;
						e.bundle[Clip.BELOW][Clip.CLIP] = 0;
						e.bundle[Clip.BELOW][Clip.SUBJ] = 0;
						
						for (int i= 0; i < num_edges; i++)
						{
							EdgeNode ei = edge_table.getNode(e_index+i);
							EdgeNode ev = edge_table.getNode(v);
							
							ei.xb    = ev.vertex.x;
							ei.bot.x = ev.vertex.x;
							ei.bot.y = ev.vertex.y;
							
							v= PREV_INDEX(v, num_vertices);
							ev = edge_table.getNode(v);
							
							ei.top.x = ev.vertex.x;
							ei.top.y = ev.vertex.y;
							ei.dx = (ev.vertex.x - ei.bot.x) / (ei.top.y - ei.bot.y);
							ei.type = type;
							ei.outp[Clip.ABOVE] = null;
							ei.outp[Clip.BELOW] = null;
							ei.next = null;
							ei.prev = null;
							ei.succ = ((num_edges > 1) && (i < (num_edges - 1))) ? edge_table.getNode(e_index+i+1) : null;
							//ei.pred = ((num_edges > 1) && (i > 0)) ? edge_table.getNode(e_index+i-1) : null;
							ei.next_bound = null;
							ei.bside[Clip.CLIP] = (op == Clip.OT_GPC_DIFF) ? Clip.RIGHT : Clip.LEFT;
							ei.bside[Clip.SUBJ] = Clip.LEFT;
						}
						insert_bound(bound_list(lmt_table, edge_table.getNode(min).vertex.y), e);
						e_index+= num_edges;
					}
				}
			}
		}
		return edge_table;
	}
	
	protected static StNode add_st_edge(StNode st, ItNodeTable it, EdgeNode edge, double dy)
	{
		if (st is null)
		{
			/* Append edge onto the tail end of the ST */
			st = new StNode(edge, null);
		}
		else
		{
			double den= (st.xt - st.xb) - (edge.xt - edge.xb);
			
			/* If new edge and ST edge don't cross */
			if((edge.xt >= st.xt) || (edge.dx == st.dx) || (abs(den) <= GPC_EPSILON))
			{
				/* No intersection - insert edge here (before the ST edge) */
				StNode existing_node = st;
				st = new StNode(edge, existing_node);
			}
			else
			{
				/* Compute intersection between new edge and ST edge */
				double r= (edge.xb - st.xb) / den;
				double x= st.xb + r * (st.xt - st.xb);
				double y= r * dy;
				
				/* Insert the edge pointers and the intersection point in the IT */
				it.top_node = add_intersection(it.top_node, st.edge, edge, x, y);
				
				/* Head further into the ST */
				st.prev = add_st_edge(st.prev, it, edge, dy);
			}
		}
		return st;
	}
	
	protected static ItNode add_intersection(ItNode it_node, 
											EdgeNode edge0, 
											EdgeNode  edge1,
											double x, 
											double y)
	{
		if (it_node is null)
		{
			/* Append a new node to the tail of the list */
			it_node = new ItNode(edge0, edge1, x, y, null);
		}
		else
		{
			if (it_node.point.y > y)
			{
				/* Insert a new node mid-list */
				ItNode existing_node = it_node;
				it_node = new ItNode(edge0, edge1, x, y, existing_node);
			}
			else
			{
				/* Head further down the list */
				it_node.next = add_intersection(it_node.next, edge0, edge1, x, y);
			}
		}
		return it_node;
	}

	// -------------
	// --- DEBUG ---
	// -------------
	protected static void print_sbt(double[] sbt)
	{
		import std.conv;
		writeln("");
		writeln(text("sbt.length=", sbt.length));
		for(int i = 0; i < sbt.length; i++)
		{
			writeln(text("sbt[", i, "]=", sbt[i]));
		}
	}
}

// ---------------------
// --- Inner Classes ---
// ---------------------
protected enum OperationType
{
	OT_Difference,
	OT_Intersection,
	OT_ExclusiveOr,
	OT_Union
}
//class OperationType
//{
//	protected string m_Type;
//	public this(string type) 
//	{ 
//		m_Type = type; 
//	}
	
//	public override string toString() { return m_Type; }
//}

/**
 * Edge intersection classes
 */
protected static class VertexType
{
	//public static final int NUL =  0; /* Empty non-intersection            */
	public static immutable int EMX =  1; /* External maximum                  */
	public static immutable int ELI =  2; /* External left intermediate        */
	//public static final int TED =  3; /* Top edge                          */
	public static immutable int ERI =  4; /* External right intermediate       */
	public static immutable int RED =  5; /* Right edge                        */
	public static immutable int IMM =  6; /* Internal maximum and minimum      */
	public static immutable int IMN =  7; /* Internal minimum                  */
	public static immutable int EMN =  8; /* External minimum                  */
	public static immutable int EMM =  9; /* External maximum and minimum      */
	public static immutable int LED = 10; /* Left edge                         */
	public static immutable int ILI = 11; /* Internal left intermediate        */
	//public static final int BED = 12; /* Bottom edge                       */
	public static immutable int IRI = 13; /* Internal right intermediate       */
	public static immutable int IMX = 14; /* Internal maximum                  */
	//public static final int FUL = 15; /* Full non-intersection             */
	
	public static int getType(int tr, int tl, int br, int bl)
	{
		return tr + (tl << 1) + (br << 2) + (bl << 3);
	}
}

/**
 * Horizontal edge states            
 */
protected class HState
{
	public static immutable int NH = 0; /* No horizontal edge                */
	public static immutable int BH = 1; /* Bottom horizontal edge            */
	public static immutable int TH = 2; /* Top horizontal edge               */
	
	/* Horizontal edge state transitions within scanbeam boundary */
	public static immutable int[][] next_h_state =
	[
		/*        Clip.ABOVE     Clip.BELOW     CROSS */
		/*        L   R     L   R     L   R */  
		/* NH */ [BH, TH,   TH, BH,   NH, NH],
		/* BH */ [NH, NH,   NH, NH,   TH, TH],
		/* TH */ [NH, NH,   NH, NH,   BH, BH]
	];
}

/**
 * Edge bundle state                 
 */
//protected enum BundleState
//{
//	UNBUNDLED,
//	BUNDLE_HEAD,
//	BUNDLE_TAIL
//}
protected class BundleState
{
	protected string m_State;

	public this(string state) pure
	{ 
		m_State = state; 
	}
	
	public static typeof(this) UNBUNDLED;   // Isolated edge not within a bundle
	public static typeof(this) BUNDLE_HEAD; // Bundle head node
	public static typeof(this) BUNDLE_TAIL; // Passive bundle tail node

	static this()
	{
		UNBUNDLED   = new BundleState("UNBUNDLED"  );
		BUNDLE_HEAD = new BundleState("BUNDLE_HEAD");
		BUNDLE_TAIL = new BundleState("BUNDLE_TAIL");
	}

	public override string toString() { return m_State; }
}

/**
 * Internal vertex list datatype
 */
protected class VertexNode
{
	double     x;    // X coordinate component
	double     y;    // Y coordinate component
	VertexNode next; // Pointer to next vertex in list
	
	public this(double x, double y)
	{
		this.x = x;
		this.y = y;
		this.next = null;
	}
}

/**
 * Internal contour / tristrip type
 */
protected class PolygonNode
{
	int active;                 /* Active flag / vertex count        */
	bool hole;                   /* Hole / external contour flag      */
	VertexNode[] v = new VertexNode[2]; /* Left and right vertex list ptrs   */
	PolygonNode next;                   /* Pointer to next polygon contour   */
	PolygonNode proxy;                  /* Pointer to actual structure used  */
	
	public this(PolygonNode next, double x, double y)
	{
		/* Make v[Clip.LEFT] and v[Clip.RIGHT] point to new vertex */
		VertexNode vn = new VertexNode(x, y);
		this.v[Clip.LEFT] = vn;
		this.v[Clip.RIGHT] = vn;
		
		this.next = next;
		this.proxy = this; /* Initialise proxy to point to p itself */
		this.active = 1; //TRUE
	}
	
	public void add_right(double x, double y)
	{
		VertexNode nv = new VertexNode(x, y);
		
		/* Add vertex nv to the right end of the polygon's vertex list */
		proxy.v[Clip.RIGHT].next= nv;
		
		/* Update proxy->v[Clip.RIGHT] to point to nv */
		proxy.v[Clip.RIGHT]= nv;
	}
	
	public void add_left(double x, double y)
	{
		VertexNode nv = new VertexNode(x, y);
		
		/* Add vertex nv to the left end of the polygon's vertex list */
		nv.next= proxy.v[Clip.LEFT];
		
		/* Update proxy->[Clip.LEFT] to point to nv */
		proxy.v[Clip.LEFT]= nv;
	}
	
}

protected class TopPolygonNode
{
	PolygonNode top_node = null;
	
	public PolygonNode add_local_min(double x, double y)
	{
		PolygonNode existing_min = top_node;
		
		top_node = new PolygonNode(existing_min, x, y);
		
		return top_node;
	}
	
	public void merge_left(PolygonNode p, PolygonNode q)
	{
		/* Label contour as a hole */
		q.proxy.hole = true;
		
		if (p.proxy != q.proxy)
		{
			/* Assign p's vertex list to the left end of q's list */
			p.proxy.v[Clip.RIGHT].next= q.proxy.v[Clip.LEFT];
			q.proxy.v[Clip.LEFT]= p.proxy.v[Clip.LEFT];
			
			/* Redirect any p.proxy references to q.proxy */
			PolygonNode target = p.proxy;
			for(PolygonNode node = top_node; (node !is null); node = node.next)
			{
				if (node.proxy == target)
				{
					node.active= 0;
					node.proxy= q.proxy;
				}
			}
		}
	}
	
	public void merge_right(PolygonNode p, PolygonNode q)
	{
		/* Label contour as external */
		q.proxy.hole = false;
		
		if (p.proxy != q.proxy)
		{
			/* Assign p's vertex list to the right end of q's list */
			q.proxy.v[Clip.RIGHT].next= p.proxy.v[Clip.LEFT];
			q.proxy.v[Clip.RIGHT]= p.proxy.v[Clip.RIGHT];
			
			/* Redirect any p->proxy references to q->proxy */
			PolygonNode target = p.proxy;
			for (PolygonNode node = top_node; (node !is null); node = node.next)
			{
				if (node.proxy == target)
				{
					node.active = 0;
					node.proxy= q.proxy;
				}
			}
		}
	}
	
	public int count_contours()
	{
		int nc = 0;
		for (PolygonNode polygon = top_node; (polygon !is null); polygon = polygon.next)
		{
			if (polygon.active != 0)
			{
				/* Count the vertices in the current contour */
				int nv= 0;
				for (VertexNode v = polygon.proxy.v[Clip.LEFT]; (v !is null); v = v.next)
				{
					nv++;
				}
				
				/* Record valid vertex counts in the active field */
				if (nv > 2)
				{
					polygon.active = nv;
					nc++;
				}
				else
				{
					/* Invalid contour: just free the heap */
					polygon.active= 0;
				}
			}
		}
		return nc;
	}
	
	public Poly getResult(TypeInfo_Class polyClass)
	{
		Poly result = Clip.createNewPoly(polyClass);
		int num_contours = count_contours();
		if (num_contours > 0)
		{
			int c= 0;
			PolygonNode npoly_node = null;
			for (PolygonNode poly_node= top_node; (poly_node !is null); poly_node = npoly_node)
			{
				npoly_node = poly_node.next;
				if (poly_node.active != 0)
				{
					Poly poly = result;
					if(num_contours > 1)
					{
						poly = Clip.createNewPoly(polyClass);
					}
					if(poly_node.proxy.hole)
					{
						poly.setIsHole(poly_node.proxy.hole);
					}
					
					// ------------------------------------------------------------------------
					// --- This algorithm puts the verticies into the poly in reverse order ---
					// ------------------------------------------------------------------------
					for (VertexNode vtx = poly_node.proxy.v[Clip.LEFT]; (vtx !is null); vtx = vtx.next)
					{
						poly.add(vtx.x, vtx.y);
					}
					if(num_contours > 1)
					{
						result.add(poly);
					}
					c++;
				}
			}
			
			// -----------------------------------------
			// --- Sort holes to the end of the list ---
			// -----------------------------------------
			Poly orig = result;
			result = Clip.createNewPoly(polyClass);
			for(int i = 0; i < orig.getNumInnerPoly(); i++)
			{
				Poly inner = orig.getInnerPoly(i);
				if(!inner.isHole())
				{
					result.add(inner);
				}
			}
			for(int i = 0; i < orig.getNumInnerPoly(); i++)
			{
				Poly inner = orig.getInnerPoly(i);
				if(inner.isHole())
				{
					result.add(inner);
				}
			}
		}
		return result;
	}
	
	public void print()
	{
		import std.conv;
		writeln("---- out_poly ----");
		int c= 0;
		PolygonNode npoly_node = null;
		for (PolygonNode poly_node= top_node; (poly_node !is null); poly_node = npoly_node)
		{
			writeln(text("contour=", c, "  active=", poly_node.active, "  hole=", poly_node.proxy.hole));
			npoly_node = poly_node.next;
			if (poly_node.active != 0)
			{
				int v=0;
				for (VertexNode vtx = poly_node.proxy.v[Clip.LEFT]; (vtx !is null); vtx = vtx.next)
				{
					writeln(text("v=", v, "  vtx.x=", vtx.x, "  vtx.y=", vtx.y));
				}
				c++;
			}
		}
	}         
}

protected class EdgeNode
{
	Point2D 		 vertex = new Point2D(); /* Piggy-backed contour vertex data  */
	Point2D 	     bot    = new Point2D(); /* Edge lower (x, y) coordinate      */
	Point2D 		 top    = new Point2D(); /* Edge upper (x, y) coordinate      */
	double         xb;           /* Scanbeam bottom x coordinate      */
	double         xt;           /* Scanbeam top x coordinate         */
	double         dx;           /* Change in x for a unit y increase */
	int            type;         /* Clip / subject edge flag          */
	int[][]        bundle = [[0, 0], [0, 0]];      /* Bundle edge flags                 */
	int[]          bside  = [0, 0];         /* Bundle left / right indicators    */
	BundleState[] bstate = [null, null]; /* Edge bundle state                 */
	PolygonNode[]  outp   = [null, null]; /* Output polygon / tristrip pointer */
	EdgeNode       prev;         /* Previous edge in the AET          */
	EdgeNode       next;         /* Next edge in the AET              */
	//EdgeNode       pred;         /* Edge connected at the lower end   */
	EdgeNode       succ;         /* Edge connected at the upper end   */
	EdgeNode       next_bound;   /* Pointer to next bound in LMT      */
}

protected class AetTree
{
	EdgeNode top_node;
	
	public void print()
	{
		writeln();
		writeln("aet");
		for(EdgeNode edge = top_node; (edge !is null); edge = edge.next)
		{
			import std.conv;
			writeln(text("edge.vertex.x=", edge.vertex.x, "  edge.vertex.y=", edge.vertex.y));
		}
	}
}

protected class EdgeTable
{
	protected EdgeNode[] m_List = [];
	
	public void addNode(double x, double y)
	{
		EdgeNode node = new EdgeNode();
		node.vertex.x = x;
		node.vertex.y = y;
		m_List ~= node;
	}
	
	public EdgeNode getNode(int index)
	{
		return m_List[index];
	}
	
	public bool FWD_MIN(int i)
	{
		EdgeNode prev = m_List[Clip.PREV_INDEX(i, m_List.length)];
		EdgeNode next = m_List[Clip.NEXT_INDEX(i, m_List.length)];
		EdgeNode ith  = m_List[i];
		return ((prev.vertex.getY() >= ith.vertex.getY()) &&
		        (next.vertex.getY() >  ith.vertex.getY()));
	}
	
	public bool NOT_FMAX(int i)
	{
		EdgeNode next = m_List[Clip.NEXT_INDEX(i, m_List.length)];
		EdgeNode ith  = m_List[i];
		return(next.vertex.getY() > ith.vertex.getY());
	}
	
	public bool REV_MIN(int i)
	{
		EdgeNode prev = m_List[Clip.PREV_INDEX(i, m_List.length)];
		EdgeNode next = m_List[Clip.NEXT_INDEX(i, m_List.length)];
		EdgeNode ith  = m_List[i];
		return ((prev.vertex.getY() >  ith.vertex.getY()) &&
		        (next.vertex.getY() >= ith.vertex.getY()));
	}
	
	public bool NOT_RMAX(int i)
	{
		EdgeNode prev = m_List[Clip.PREV_INDEX(i, m_List.length)];
		EdgeNode ith  = m_List[i];
		return (prev.vertex.getY() > ith.vertex.getY());
	}
}

/**
 * Local minima table
 */
protected class LmtNode
{
	double   y;            /* Y coordinate at local minimum     */
	EdgeNode first_bound;  /* Pointer to bound list             */
	LmtNode  next;         /* Pointer to next local minimum     */
	
	public this(double yvalue)
	{
		y = yvalue;
	}
}

protected class LmtTable
{
	LmtNode top_node;
	
	public void print()
	{
		import std.conv;
		int n = 0;
		LmtNode lmt = top_node;
		while(lmt !is null)
		{
			writeln(text("lmt(", n, ")"));
			for(EdgeNode edge = lmt.first_bound; (edge !is null); edge = edge.next_bound)
			{
				writeln(text("edge.vertex.x=", edge.vertex.x, "  edge.vertex.y=", edge.vertex.y));
			}
			n++;
			lmt = lmt.next;
		}
	}
}

/**
 * Scanbeam tree 
 */
protected class ScanBeamTree
{
	double       y;            /* Scanbeam node y value             */
	ScanBeamTree less;         /* Pointer to nodes with lower y     */
	ScanBeamTree more;         /* Pointer to nodes with higher y    */
	
	public this(double yvalue)
	{
		y = yvalue;
	}
}

/**
 *
 */
protected class ScanBeamTreeEntries
{
	int sbt_entries;
	ScanBeamTree sb_tree;
	
	public double[] build_sbt()
	{
		double[] sbt = [];
		sbt.length = sbt_entries;
		
		int entries = 0;
		entries = inner_build_sbt(entries, sbt, sb_tree);
		if(entries != sbt_entries)
		{
			assert(0, "Something went wrong building sbt from tree.");
		}
		return sbt;
	}
	
	protected int inner_build_sbt(int entries, double[] sbt, ScanBeamTree sbt_node)
	{
		if(sbt_node.less !is null)
		{
			entries = inner_build_sbt(entries, sbt, sbt_node.less);
		}
		sbt[entries]= sbt_node.y;
		entries++;
		if(sbt_node.more !is null)
		{
			entries = inner_build_sbt(entries, sbt, sbt_node.more);
		}
		return entries;
	}
}

/**
 * Intersection table
 */
protected class ItNode
{
	EdgeNode[]     ie    = [null, null];      /* Intersecting edge (bundle) pair   */
	Point2D		 point = new Point2D(); /* Point of intersection             */
	ItNode         next;                         /* The next intersection table node  */
	
	public this(EdgeNode edge0, EdgeNode edge1, double x, double y, ItNode next)
	{
		this.ie[0] = edge0;
		this.ie[1] = edge1;
		this.point.x = x;
		this.point.y = y;
		this.next = next;
	}
}

protected class ItNodeTable
{
	ItNode top_node;
	
	public void build_intersection_table(AetTree aet, double dy)
	{
		StNode st = null;
		
		/* Process each AET edge */
		for (EdgeNode edge = aet.top_node; (edge !is null); edge = edge.next)
		{
			if((edge.bstate[Clip.ABOVE] == BundleState.BUNDLE_HEAD) ||
			   (edge.bundle[Clip.ABOVE][Clip.CLIP] != 0) ||
			   (edge.bundle[Clip.ABOVE][Clip.SUBJ] != 0))
			{
				st = Clip.add_st_edge(st, this, edge, dy);
			}
		}
	}
}

/**
 * Sorted edge table
 */
protected class StNode
{
	EdgeNode edge;         /* Pointer to AET edge               */
	double   xb;           /* Scanbeam bottom x coordinate      */
	double   xt;           /* Scanbeam top x coordinate         */
	double   dx;           /* Change in x for a unit y increase */
	StNode   prev;         /* Previous edge in sorted list      */
	
	public this(EdgeNode edge, StNode prev)
	{
		this.edge = edge;
		this.xb = edge.xb;
		this.xt = edge.xt;
		this.dx = edge.dx;
		this.prev = prev;
	}      
}