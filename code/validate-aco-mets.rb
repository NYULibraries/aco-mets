#!/usr/bin/env ruby

require 'nokogiri'
require 'digest'
require 'open-uri'
require 'awesome_print'
require 'fileutils'

=begin

http://stackoverflow.com/questions/13070404/xpath-along-with-nokogiri-tutorials-examples

This script validates incoming aco mets documents.

Assertions:
1.) METS file validates against schema
2.) all files mentioned in all parts of document:
    * are present
    * have checksum values
    * pass fixity check
3.) specific file checks
      eoc file present
      calibration files present
      marcxml file(s) present
      target files present
      master filegrp present
4.) struct map div
      TYPE contains recognized values
        SOURCE_ENTITY:TEXT
        ONE_TO_ONE_ENTITY:TEXT
        INTELLECTUAL_ENTITY:TEXT
        SCAN_ORDER
        READ_ORDER
        BINDING_ORIENTATION
    intellectual entity div
        @TYPE:
          INTELLECTUAL_ENTITY
     slot div:
       @TYPE
         LOCATION
         TYPE
=end
# TODO: refactor into gem. nyudl-aco-mets

class FileElementBase
  attr_reader :errors
  def initialize(f)
    @f = f
    assert_element_type
    @errors = []
    @validated = false
  end
  def valid?
    @validated ? @errors.empty? : nil
  end
  def validate
    @errors = []
    validate_path
    validate_checksum
    @validated = true
  end

  private
  def assert_element_type
    raise NotImplementedError
  end
  def extract_path
    raise NotImplementedError
  end

  def validate_path
    @path = nil
    path = extract_path
    @errors << "could not determine path." if path.nil?
    File.exists?(path) ? @path = path : @errors << "file not found: #{path}"
  end

  def validate_checksum
    @checksum     = @f['CHECKSUM']
    @checksumtype = @f['CHECKSUMTYPE']
    @errors << "missing attribute: 'CHECKSUM'"     if @checksum.nil?
    @errors << "missing attribute: 'CHECKSUMTYPE'" if @checksumtype.nil?

    if @path
      validator = get_checksum_validator
      calculated_checksum = validator.file(@path).hexdigest
      @errors << "fixity check failed: expected #{@checksum} got #{calculated_checksum}" unless @checksum == calculated_checksum
    else
      @errors << "could not calculate checksum due to missing invalid path"
    end
  end

  def get_checksum_validator
    case @checksumtype
    when 'SHA-512' then Digest::SHA512
    when 'SHA-384' then Digest::SHA384
    when 'SHA-256' then Digest::SHA256
    when 'SHA-1'   then Digest::SHA1
    when 'MD5'     then Digest::MD5
    else
      raise "unrecognized CHECKSUMTYPE: @checksumtype"
    end
  end
end


class FileElement < FileElementBase
  private
  def assert_element_type
    raise "incorrect element type: #{@f.name}, expecting file" unless @f.name == 'file'
  end
  def extract_path
    raise "incorrect number of FLocat elements" unless @f.search('FLocat').length == 1
    @f.search('FLocat')[0]['xlink:href']
  end
end


class MdRefElement < FileElementBase
  private
  def assert_element_type
    raise "incorrect element type: #{@f.name}, expecting mdRef" unless @f.name == 'mdRef'
  end
  def extract_path
    path  = @f['xlink:href']
    @errors << "missing 'xlink:href' attribute. could not determine path." if path.nil?
    path
  end
end

class ACOMETSValidator
  attr_reader :errors
  METS_SCHEMA_URL='http://www.loc.gov/standards/mets/version191/mets.xsd'

  def initialize(path, options = {})
    @doc       = Nokogiri::XML(File.read(path))
    @dir       = options[:dir] || '.'
    @partner   = options[:partner]
    @digi_id   = options[:digi_id]
    @errors    = {}
    @validated = false
    @options   = options
  end

  def valid?
    @validated ? @errors.empty? : nil
  end

  def validate
    @validated = false
    @errors = {}
    validate_against_xsd
    validate_mdrefs
    validate_files
    check_eoc
    check_calibration_files
    check_marcxml
    check_filegrp_master
    check_structmap_attributes
    check_structmap_intellectual_entities
    check_structmap_file_slot_attributes
    @validated = true
  end

  private

  def check_structmap_attributes
    errors = []
    valid_subtypes = %w(SOURCE_ENTITY:TEXT
                        ONE_TO_ONE_ENTITY:TEXT
                        INTELLECTUAL_ENTITY
                        BINDING_ORIENTATION:VERTICAL
                        BINDING_ORIENTATION:HORIZONTAL
                        SCAN_ORDER:LEFT_TO_RIGHT
                        SCAN_ORDER:RIGHT_TO_LEFT
                        SCAN_ORDER:TOP_TO_BOTTOM
                        SCAN_ORDER:BOTTOM_TO_TOP
                        READ_ORDER:LEFT_TO_RIGHT
                        READ_ORDER:RIGHT_TO_LEFT
                        READ_ORDER:TOP_TO_BOTTOM
                        READ_ORDER:BOTTOM_TO_TOP)
    s_node_set = @doc.search('structMap')

    struct_map_cnt = s_node_set.length
    if struct_map_cnt == 1
      s = s_node_set[0]
      s['TYPE'].split(' ').each do |st|
        errors << "unrecognized type: #{st}" unless valid_subtypes.include?(st)
      end
    else
      errors << "unexpected structMap count: got #{struct_map_cnt}, expected 1" unless struct_map_cnt == 1
    end

    @errors[:structmap_attributes] = errors unless errors.empty?
  end

  def check_filegrp_master
    found_it = false
    @doc.search('fileGrp').each do |d|
      if d['USE'] == 'MASTER'
        found_it = true
        break
      end
    end
    @errors[:filegrp_master] = "could not find MASTER fileGrp" unless found_it
  end

  def check_eoc
    found_it = false
    @doc.search('digiprovMD').each do |d|
      if d.search('mdRef')[0]['OTHERMDTYPE'] == 'NYU-DLTS-EOC'
        found_it = true
        break
      end
    end
    @errors[:eoc] = "could not find eoc file" unless found_it
  end

  def check_marcxml
    errors = []
    found_it = false
    @doc.search('dmdSec').each do |d|
      if d.search('mdRef').each do |m|
          found_it = true if m['OTHERMDTYPE'] == 'MARCXML'
          filename = m['xlink:href']
          # TODO : add support for multiple IEs (bound-with)
          # TODO : parse IEs in dirname
          errors << "badly formatted marcxml filename: #{filename}" unless /\A#{@partner}_(\w+)_marcxml.xml\z/.match(filename)
        end
      end
    end
    errors << "could not find marcxml file" unless found_it
    @errors[:marcxml] = errors unless errors.empty?
  end

  def check_calibration_files
    expected_cnt    = 2
    calibration_cnt = 0
    @doc.search('digiprovMD').each do |d|
      if d.search('mdRef')[0]['OTHERMDTYPE'] == 'CALIBRATION-TARGET-IMAGE'
        calibration_cnt += 1
      end
    end
    @errors[:calibration_files] = "calibration file count incorrect: expected #{expected_cnt} got #{calibration_cnt}" unless calibration_cnt == expected_cnt
  end

  def validate_against_xsd
    xsd = Nokogiri::XML::Schema(open(METS_SCHEMA_URL))
    errors = xsd.validate(@doc)
    @errors[:xsd] = errors unless errors.empty?
  end

  def validate_mdrefs
    @doc.search('mdRef').each do |m|
      m_el = MdRefElement.new(m)
      m_el.validate
      unless m_el.valid?
        @errors[:mdrefs].nil? ? @errors[:mdrefs] = m_el.errors : @errors[:mdrefs] << m_el.errors
      end
    end
  end

  def validate_files
    @doc.search('file').each do |f|
      f_el = FileElement.new(f)
      f_el.validate
      unless f_el.valid?
        @errors[:files].nil? ? @errors[:files] = f_el.errors : @errors[:files] << f_el.errors
      end
    end
  end

  def check_structmap_intellectual_entities
    errors = []
    @doc.xpath('xmlns:mets/xmlns:structMap/xmlns:div/xmlns:div').each do |el|
      t = el['TYPE']
      errors << "Incorrect div TYPE attribute. expected 'INTELLECTUAL_ENTITY' got '#{t}'" unless t == 'INTELLECTUAL_ENTITY'
    end
    @errors[:struct_map_ie] = errors unless errors.empty?
  end

  def check_structmap_file_slot_attributes
    valid_subtypes = %w(LEFT RIGHT TOP BOTTOM PAGE INSERT UNNUMBERED PAGE_ALT
                        PAGE_MISSING PAGE_DEFECTIVE OVERSIZED)

    errors = []
    s = @doc.search('structMap')[0]
    order = 0
    s.search('fptr') do |fp|
      order += 1
      node_order = fp.parent['ORDER'].to_i
      errors << "incorrect order: expected #{order} got #{node_order}" unless order == node_order
      fp.parent['TYPE'].split(' ').each do |st|
        errors << "unrecognized type: #{st}" unless valid_subtypes.include?(st)
      end
    end
    @errors[:page_attributes] = errors unless errors.empty?
  end
end


# TODO: split this out into a separate aco-pul sip validator
#       the METS validator should be a subset of overall validation
#       check directory structure:
#       princeton_foo
#                      ./princeton_foo_mets.xml
#                      ./princeton_foo_marcxml.xml


mets_file_path = ARGV[0]

raise "expecting a METS file" unless File.file?(mets_file_path)

dir = File.expand_path(File.dirname(mets_file_path))

mets_file_name = File.basename(mets_file_path)

partner, digi_id = mets_file_name.split('_')

expected_mets_filename = 'princeton' + '_' + digi_id + '_' + 'mets.xml'
raise "unexpected mets filename: expected #{expected_mets_filename}, got #{mets_file_name}" unless mets_file_name == expected_mets_filename

puts "#{mets_file_name}"
puts "#{dir}"


amv = ACOMETSValidator.new(mets_file_path, {path: dir, partner: partner, digi_id: digi_id})

amv.validate

exit 0 if amv.valid?

ap amv.errors
exit 1
