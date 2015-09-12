require 'base64'
require 'openssl'

# @author Joseph Catera
=begin
This class encodes and encrypts a username and a password
using the OpenSSL library. The encoded/encrypted
credentials are then written to a hidden file.
The credentials can be decoded/decrypted with the
same class. 
The main purpose of this class is to allow users
to use Basic auth credentials without providing
them on the command line each time when
calling a Web API.
=end

class Creds
  
  CREDS_FILE = ".creds"
  @@iter = 20000

  attr_accessor :username, :password, :pass_phrase, :encryptor, :encrypted, :decryptor, :decrypted, :key, :salt, :iv, :pw_str

  # @!method initialize(username="", password="")
  # Stores the credentials, encodes a passphrase, creates the salt, encryptor, and decryptor.
  # @param username [String] the username
  # @param password [String] the password
  # @return None
  def initialize(username="", password="")
    @username = username || ""
    @password = password  || ""
    @pw_str = ""
    @pass_phrase = Base64.encode64(`whoami`.chomp + Time.new.to_s)
    @encryptor = OpenSSL::Cipher.new 'AES-128-CBC'
    @enrypted = nil
    @decryptor = OpenSSL::Cipher.new 'AES-128-CBC'
    @decrypted = nil
    @key = nil
    @salt = OpenSSL::Random.random_bytes 16
    @iv = nil   
  end 
  # @!method get_creds
  # Gets credentials from file.
  # (see #read_key)
  # @return [Array] Contains the decoded/decrypted username and password. 
  def get_creds
    read_key
    @decryptor.decrypt
    @decryptor.iv = @iv
    @key_len = @decryptor.key_len
    @pass_phrase = Base64.decode64(@pass_phrase)
    hmac_sha1_key
    @decryptor.key = @key
    begin 
      @decrypted = @decryptor.update @encrypted
      @decrypted << @decryptor.final
    rescue Exception => e
      return @username, @password = false, false
    end
    @username, @password = @decrypted.split(":")
  end
  # @!method validate_creds(un, pw)
  # Validates whether the given credentials match those that have been written to file.
  # (see #get_creds)
  # @param un [String] the username
  # @param pw [String] the password 
  # @return [Boolean] Returns true if creds match and false if they don't.
  def validate_creds(un, pw)
    get_creds
    if un == @username and pw == @password
      return true
    else
      return false
    end
  end
  # @!method write_creds
  # Writes encoded and encrypted credentials to file.
  # (see #set_pw_str)
  # @return None
  def write_creds
    set_pw_str
    @encryptor.encrypt
    @iv = @encryptor.random_iv
    @pass_phrase = Base64.decode64(@pass_phrase)
    @key_len = @encryptor.key_len
    hmac_sha1_key
    @encryptor.key = @key
    @encrypted = @encryptor.update @pw_str
    @encrypted << @encryptor.final
    @pass_phrase = Base64.encode64(@pass_phrase)
    write_key
  end
  private
  # @!method set_pw_str
  # Sets the string of the username and password: <username>:<password>
  # @private
  # @return [String] 
  def set_pw_str
    if @username == "" or @password == ""
      raise  Excection "Username and password have not been set yet."
    else
      @pw_str = [@username,@password].join(":")
    end
  end
  # @!method read_key
  # Reads the keys from the credential file: iv, salt, pass phrase, encrypted string
  # and assigns those values to instance variables.
  # @private
  # @return None
  def read_key
     begin
       fd = File.new(CREDS_FILE, "rb")
       @iv = fd.read(16)
       @salt = fd.read(16)
       pl = fd.read(2)
       @pass_phrase = fd.read(pl.to_i)
       enc_size = fd.read(2)
       @encrypted = fd.read(enc_size.to_i)
       fd.close
     rescue Exception => e
       puts e.message
     end
  end
  # @!method write_key
  # Writes the keys to the credential file: iv, salt, pass phrase, encrypted string.
  # @private
  # @return None
  def write_key
    pass_len = @pass_phrase.size
    enc_len = @encrypted.size
    fd = File.new(CREDS_FILE, 'wb')
    fd.write @iv
    fd.write @salt
    fd.write pass_len
    fd.write @pass_phrase
    fd.write enc_len
    fd.write @encrypted
    fd.close
  end
  # @!method hmac_sha1_key
  # Creates the key from a HMAC SHA1 based on the pass phrase, salt, iteration, and key length
  # and assigns that to the instance variable `@key`.
  # @private
  # @return None
  def hmac_sha1_key
    @key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(@pass_phrase, @salt, @@iter, @key_len)
  end
end
