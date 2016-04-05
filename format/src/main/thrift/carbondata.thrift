/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/**
 * File format description for the carbon file format
 */
namespace java org.carbondata.format

include "schema.thrift"

/**
* Information about a segment, that represents one data load
*/
struct SegmentInfo{
	1: required i32 num_cols; // Number of columns in this load, because schema can evolve . TODO: Check whether this is really required
	2: required list<i32> column_cardinalities; // Cardinality of columns
}

/**
*	Btree index of one node.
*/
struct LeafNodeBTreeIndex{
	1: required binary start_key; // Bit-packed start key of one leaf node
	2: required binary end_key;	// Bit-packed start key of one leaf node
}

/**
*	Min-max index of one complete file
*/
struct LeafNodeMinMaxIndex{
	1: required list<binary> min_values; //Min value of all columns of one leaf node Bit-Packed
	2: required list<binary> max_values; //Max value of all columns of one leaf node Bit-Packed
}

/**
*	Index of all leaf nodes in one file
*/
struct LeafNodeIndex{
	1: optional list<LeafNodeMinMaxIndex> min_max_index;
	2: optional list<LeafNodeBTreeIndex> b_tree_index;
}

/**
* Sort state of one column
*/
enum SortState{
	SORT_NONE = 0; // Data is not sorted
	SORT_NATIVE = 1; //Source data was sorted
	SORT_EXPLICIT = 2;	// Sorted (ascending) when loading
}

/**
*	Compressions supported by Carbon Data.
*/
enum CompressionCodec{
	SNAPPY = 0;
}

/**
* Represents the data of one dimension one dimension group in one leaf node
*/
// add a innger level placeholder for further I/O granulatity
struct ChunkCompressionMeta{
	1: required CompressionCodec compression_codec; // the compressor used
	/** total byte size of all uncompressed pages in this column chunk (including the headers) **/
	2: required i64 total_uncompressed_size;
	/** total byte size of all compressed pages in this column chunk (including the headers) **/
	3: required i64 total_compressed_size;
}

/**
* To handle space data with nulls
*/
struct PresenceMeta{
	1: required bool represents_presence; // if true, ones in the bit stream reprents presence. otherwise represents absence
	2: required binary present_bit_stream; // Compressed bit stream representing the presence of null values
}

/**
* Represents a chunk of data. The chunk can be a single column stored in Column Major format or a group of columns stored in Row Major Format.
**/
struct DataChunk{
	1: required ChunkCompressionMeta chunk_meta; // the metadata of a chunk
	2: required bool row_chunk; // whether this chunk is a row chunk or column chunk ? Decide whether this can be replace with counting od columnIDs
	/** The column IDs in this chunk, in the order in which the data is physically stored, will have atleast one column ID for columnar format, many column ID for row major format**/
	3: required list<i32> column_ids;
	4: required i64 data_page_offset; // Offset of data page
	5: required i32 data_page_length; // length of data page
	6: optional i64 rowid_page_offset; //offset of row id page, only if encoded using inverted index
	7: optional i32 rowid_page_length; //length of row id page, only if encoded using inverted index
	8: optional i64 rle_page_offset;	// offset of rle page, only if RLE coded.
	9: optional i32 rle_page_length;	// length of rle page, only if RLE coded.
	10: optional PresenceMeta presence; // information about presence of values in each row of this column chunk
	11: optional SortState sort_state;
    12: optional list<schema.Encoding> encoders; // The List of encoders overriden at node level
    13: optional list<binary> encoder_meta; // extra information required by encoders
}


/**
*	Information about a leaf node
*/
struct LeafNodeInfo{
    1: required i32 num_rows;	// Number of rows in this leaf node
    2: required list<DataChunk> dimension_chunks;	// Information about dimension chunk of all dimensions in this leaf node
    3: required list<DataChunk> measure_chunks;	// Information about measure chunk of all measures in this leaf node
}

/**
* Description of one data file
*/
struct FileMeta{
	1: required i32 version; // version used for data compatibility
	2: required i64 num_rows; // Total number of rows in this file
	3: required SegmentInfo segment_info;	// Segment info (will be same/repeated for all files in this segment)
	4: required LeafNodeIndex index;	// Leaf node index of all leaf nodes in this file
	5: required list<schema.ColumnSchema> table_columns;	// Description of columns in this file
	6: required list<LeafNodeInfo> leaf_node_info;	// Information about leaf nodes of all columns in this file
}
