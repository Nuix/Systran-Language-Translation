import javax.swing.JDialog
import javax.swing.JFrame
import javax.swing.JPanel
import javax.swing.JLabel
import javax.swing.JComboBox
import javax.swing.JTextField
import java.awt.Font
import javax.swing.JProgressBar
import javax.swing.JOptionPane


def getTextInput(settings,title)
	if(settings.class!=Hash) 
		raise "settings are expected in hash values, e.g. {\"label\"=>\"default value for text\"}"
	end
	panel = JPanel.new(java.awt.GridLayout.new(0,2))
	
	controls=Array.new()
	settings.each do | setting,value|
		lbl=JLabel.new(setting)
		panel.add(lbl)
		cb = JTextField.new
		cb.setText(value.to_s)
		cb.name=setting
		cb.setFocusable(true)
		panel.add(cb)
		controls.push cb
	end
	JOptionPane.showMessageDialog(JFrame.new, panel,title,JOptionPane::PLAIN_MESSAGE );

	responses=Hash.new()
	controls.each do | control|
		responses[control.name]=control.getText()
	end
	return responses
end

def getComboInput(settings,title)
	if(settings.class!=Hash) 
		raise "settings are expected in Array values, e.g. {\"label\"=>[\"Value1\",\"Value2\"]}"
	end
	panel = JPanel.new(java.awt.GridLayout.new(0,2))
	
	controls=Array.new()
	settings.each do | setting,value|
		lbl=JLabel.new("#{setting}")
		panel.add(lbl)
		cb = JComboBox.new value.to_java
		cb.name=setting
		cb.setFocusable(false)
		panel.add(cb)
		controls.push cb
	end
	JOptionPane.showMessageDialog(JFrame.new, panel,title,JOptionPane::PLAIN_MESSAGE );

	responses=Hash.new()
	controls.each do | control|
		responses[control.name]=control.getSelectedItem.to_s
	end
	return responses
end


class TranslateDialog < JDialog
	def initialize(title)
		super nil, true
		self.setTitle(title)
		self.setSize(400, 265)
		self.setAlwaysOnTop(true)
		self.setResizable(false)
		self.setLayout(nil)
		self.setLocationRelativeTo(nil)
		self.setDefaultCloseOperation(JFrame::DISPOSE_ON_CLOSE)

		@jlabelTranslate = JLabel.new() 
		@jlabelTranslate.setSize(370, 15)
		@jlabelTranslate.setLocation(10,10)
		@jlabelTranslate.setFont(@jlabelTranslate.getFont().deriveFont(Font::BOLD))
		@jlabelTranslate.setText("Translating:")

		@jlabelTranslateMessage = JLabel.new() 
		@jlabelTranslateMessage.setSize(370, 15)
		@jlabelTranslateMessage.setLocation(10,35)

		@jlabelTranslateProgress = JProgressBar.new() 
		@jlabelTranslateProgress.setSize(370, 20)
		@jlabelTranslateProgress.setLocation(10,60)
		@jlabelTranslateProgress.setStringPainted(true)

		@jlabelImport = JLabel.new() 
		@jlabelImport.setSize(370, 15)
		@jlabelImport.setLocation(10,100)
		@jlabelImport.setFont(@jlabelImport.getFont().deriveFont(Font::BOLD))
		@jlabelImport.setText("Importing:")

		@jlabelImportMessage = JLabel.new() 
		@jlabelImportMessage.setSize(370, 15)
		@jlabelImportMessage.setLocation(10,125)

		@jlabelImportProgress = JProgressBar.new() 
		@jlabelImportProgress.setSize(370, 20)
		@jlabelImportProgress.setLocation(10,150)
		@jlabelImportProgress.setStringPainted(true)
		
		

		self.add(@jlabelTranslate)
		self.add(@jlabelTranslateMessage)
		self.add(@jlabelTranslateProgress)
		self.add(@jlabelImport)
		self.add(@jlabelImportMessage)
		self.add(@jlabelImportProgress)

		Thread.new{
				yield self
			sleep(0.2)
			self.dispose()
		}
		self.setVisible(true)

	end

	def setTranslateMax(max)
		@jlabelTranslateProgress.setMaximum(max)
	end


	def setTranslateCurrent(current)
		@jlabelTranslateProgress.setValue(current)
	end

	def setTranslateMessage(message)
		@jlabelTranslateMessage.setText(message)
	end

	def setImportMax(max)
		@jlabelImportProgress.setMaximum(max)
	end


	def setImportCurrent(current)
		@jlabelImportProgress.setValue(current)
	end

	def setImportMessage(message)
		@jlabelImportMessage.setText(message)
	end

	def close()
		self.setVisible(false)
		self.dispose()
	end
end


require 'uri'
require 'net/https'
require 'json'
require 'thread'

class Systran
	attr_accessor :version, :profiles, :languages, :formats
	def initialize(url,key)
		@url=url
		@key=key
		@batches={}
		@version=doCall('/translation/apiVersion')["version"]
		if(@version!="2.5.0")
			puts("WARN:Version of api differs from the 2.5.0 that this script was tested with. Oddities may occur")
		end
		puts("Running Systran test for version:#{@version}")
		#@profiles=doCall('/translation/profiles')["profiles"]
		@languages=doCall('/translation/supportedLanguages')["languagePairs"].map{|language|
			languageDetails={
				"source"=>language['source'],
				"target"=>language['target'],
			}
			javaLocale=java.util.Locale.new(languageDetails['source'].split('-')[0])
			languageDetails['source3Letter']=javaLocale.getISO3Language() #used for intelligent lookups from nuix's language detection.
			languageDetails
		}
		#@formats=doCall('/translation/supportedFormats')["formats"]
	end

	#do not call outside this class...
	def doCall(path,type='get',content=nil)
		begin
			uri = URI.parse(@url + path)
			http = Net::HTTP.new(uri.host, uri.port)
			http.read_timeout=500
			if(uri.scheme=="https")
				http.use_ssl = true
			end
			req=nil
			response=""
			case
				when type=='get'
					req = Net::HTTP::Get.new(uri)
					req["Authorization"]="Key " + @key
					res = http.request(req)
					response=res.body()
				when type=='post'
					req = Net::HTTP::Post.new(uri)
					req["Authorization"]="Key " + @key
					req.set_form(content, 'multipart/form-data')
					res=http.request(req)
					response=res.body
				else
					puts "type is unknown!!"
			end
			
			if(response.include? '<!DOCTYPE html>')
				status,message=response.match(/(?<=<title>).*?(?=<\/title>)/)[0].split("|")[1].split(":").map{|a|a.strip()}
				return {"error"=>{"status"=>status,"message"=>message}}
			end
			begin
				return JSON.parse(response)
			rescue Exception=> ex
				#not json
			end
			parts=response.split(/#{response.lines[0].strip()}-*/).map{|a|a.strip()}.select{|a|a.length > 0}
			content={}
			parts.each do | part|
				if(!part.lines[0].split(':')[1].nil?)
					name=part.lines[0].split(':')[1].strip()
					value=part.lines.drop(2).join("\n")
					if(name=='output')
						content[name]=value
					else
						content[name]=JSON.parse(value)
					end
				else
					puts response # whats up with this content?
				end
			end
			return content
		rescue Exception => ex
			puts ex
			puts ex.backtrace
			return {"error"=>{"status"=>-1,"message"=>ex.message}}
		end
	end
	
	def withBatch()
		result=doCall('/translation/file/batch/create','post',{})
		batchId=result["batchId"]
		@batches[batchId]={}
		begin
			yield batchId
		rescue Exception => ex
			puts ex
			puts ex.backtrace
		end
		if(@batches.has_key? batchId)
			closeBatch(batchId)
		end
		@batches.delete(batchId)
	end
	
	def closeBatch(batchId)
		#when finished close batch
		doCall('/translation/file/batch/close','post',{'batchId'=>batchId})
	end
	
	def withBatchResults(batchId)
		#poll the batch every second until it's finished
		finishedAt=nil
		while(finishedAt.nil?)
			sleep(1)
			result=doCall('/translation/file/batch/status?batchId=' + batchId)
			if(result["cancelled"] || result["expireAt"] || result["finishedAt"])
				finishedAt=result["finishedAt"]
			end
			finishedRequests=result["requests"].select{|request|["finished","error"].include? request["status"].downcase}
											   .select{|request|@batches[batchId].has_key? request["id"]["$oid"]}
			finishedRequests.each do | finishedRequest |
				requestId=finishedRequest["id"]["$oid"]
				if(finishedRequest["status"]=="finished")
					translationResult=doCall('/translation/file/result?requestId=' + requestId)
				else
					statusResult=doCall('/translation/file/status?requestId=' + requestId)
					translationResult={
					
						"error"=>{
							"status"=>statusResult["status"],
							"message"=>statusResult["description"],
							"additional"=>statusResult
						}
					}
				end
				begin
					sourceLanguage,item=@batches[batchId][requestId]
					yield sourceLanguage,item,translationResult,requestId
				rescue Exception => ex
					puts ex
					puts ex.backtrace
				end
				@batches[batchId].delete(requestId)
			end
		end
		
	end


	def translate(sourceLanguage,targetLanguage,batchId,item)
		text=item.getTextObject().toString()
		textlines=text.gsub(/\s*[\n\r\t\u00a0]+\s*/,"\n")
		if(textlines.length > 1000000)
			textlines=textlines[0, 1000000]
			puts "Warning:#{item.getGuid()} has more than 1 Million characters, only sending 1 Million"
		end
		requestId=doCall('/translation/file/translate','post',{"input"=>textlines,"source"=>sourceLanguage,"target"=>targetLanguage,"withInfo"=>"true","async"=>"true","batchId"=>batchId})["requestId"]
		@batches[batchId][requestId]=[sourceLanguage,item]
	end
end



CONFIG=getTextInput({"location"=>"https://api-translate.systran.net","key"=>""},"Configuration")
systran=Systran.new(CONFIG['location'],CONFIG['key'])
LANGUAGE_SOURCE=getComboInput({"Source"=>(['nuix-auto','auto'] + systran.languages.map{|languageDetails|languageDetails["source"]}.uniq.sort())},"Source")["Source"]


targetLanguages=systran.languages.select{|languageDetails|((languageDetails["source"]==LANGUAGE_SOURCE) || (LANGUAGE_SOURCE.include? 'auto'))}.map{|languageDetails|languageDetails["target"]}.uniq.sort()
if(targetLanguages.include? ENV_JAVA["user.language"])
	targetLanguages=[ENV_JAVA["user.language"]] + (targetLanguages-[ENV_JAVA["user.language"]]) #put the users language at the top!
end
LANGUAGE_TARGET=getComboInput({"Target"=>targetLanguages},"Target")["Target"]

$window.closeAllTabs()
TranslateDialog.new("Translating") do | dialog |
	currentCase.withWriteAccess do
		iu=$utilities.getItemUtility()
		nuixItems=currentCase.searchUnsorted('NOT custom-metadata:"language-id":* AND content:*') #probably best to add to this query with the users language preference being removed also...
		if(!currentSelectedItems.nil?)
			if(currentSelectedItems.length > 0)
				nuixItems=iu.intersection(currentSelectedItems,nuixItems) #anything with text that hasn't been translated
			end
		end
		itemIterator=nuixItems.iterator()
		
		dialog.setTranslateMax(nuixItems.size())
		dialog.setImportMax(nuixItems.size())
		
		total=nuixItems.size()
		systran.withBatch() do | batchId |
			puts "Starting Batch: #{batchId}"
			threads=[]
			threads << Thread.new do
				queued=0
				uploadThreads=[]
				itemTracker = Mutex.new
				statTracker = Mutex.new
				0.upto(9) do | threadIndex |
					sleep(0.5) #adding a tiny breather here in case cloudfare/DDoS is detected... This seems all
					uploadThreads << Thread.new do
						item=nil
						itemTracker.synchronize {
							if(itemIterator.hasNext())
								item=itemIterator.next()
							end
						}
						while(!item.nil?)
							statTracker.synchronize {
								queued=queued+1
								dialog.setTranslateCurrent(queued)
								dialog.setTranslateMessage("Queued:#{queued} items")
							}
							sourceLanguage=LANGUAGE_SOURCE
							if(sourceLanguage=='nuix-auto')
								sourceOptions=systran.languages.select{|l|l['source3Letter']==item.getLanguage()}
								if(sourceOptions.length > 0)
									sourceLanguage=sourceOptions.first()['source']
								else
									sourceLanguage='auto' #can't determine appropriate language from the possible options...
									puts "Can't locate translation option for Language:#{item.getLanguage()}"
								end
							end
							if(sourceLanguage == LANGUAGE_TARGET) #no point translating... e.g english to english.
								statTracker.synchronize {
									total=total-1
									dialog.setTranslateMax(total)
									dialog.setImportMax(total)
								}
							else
								systran.translate(sourceLanguage,LANGUAGE_TARGET,batchId,item)
							end
							itemTracker.synchronize {
								if(itemIterator.hasNext())
									item=itemIterator.next()
								else
									item=nil
								end
							}
						end
						
					end
				end
				uploadThreads.each(&:join)
				puts "finished queuing items"
				systran.closeBatch(batchId)
			end
			errors=0
			threads << Thread.new do
				translated=0
				systran.withBatchResults(batchId) do | sourceLanguage,item,translationResult,requestId |
					customMetadata=item.getCustomMetadata()
					if(translationResult.has_key? "error")
						errors=errors+1
						begin
							customMetadata.putText("Language-error-status",translationResult["error"]["status"])
							customMetadata.putText("Language-error-message",translationResult["error"]["message"])
							customMetadata.putText("Language-error-details",{"batchId"=>batchId,"requestId"=>requestId,"result"=>translationResult}.to_json)
						rescue Exception => ex
							puts ex
							puts ex.backtrace
						end
					else
						if(!translationResult.has_key? 'info')
							translationResult['info']={}
						end
						if(!(translationResult['info'].has_key? 'lid')) #using the user defined option
							translationResult['info']['lid']={
								'language'=>sourceLanguage,
								'confidence'=>1 #of course we are highly confident in users right? :P
							}
						end
						textBlob=item.getTextObject().toString()
						blob=textBlob + "\n\n============ TRANSLATED (#{translationResult['info']['lid']['language']} #{(translationResult['info']['lid']['confidence'] * 100).round(2)}%) ============\n\n" + translationResult["output"]
						begin
							item.modify do |item_modifier|
								item_modifier.replaceText(textBlob + "\n\n============ TRANSLATED (#{translationResult['info']['lid']['language']} #{(translationResult['info']['lid']['confidence'] * 100).round(2)}%) ============\n\n" + translationResult["output"])
							end
							begin
								customMetadata.putText("Language-id",translationResult['info']['lid']['language'])
								customMetadata.putFloat("Language-confidence",translationResult['info']['lid']['confidence'])
								translationResult['info']['stats'].each do | key, value|
									customMetadata.putInteger("Language-" + key,value)
								end
								customMetadata.remove("Language-error-status")
								customMetadata.remove("Language-error-message")
								customMetadata.remove("Language-error-details")
							rescue Exception => ex
								puts ex
								puts ex.backtrace
							end
							translated=translated+1
						rescue Exception => ex
							puts ex.message
							puts ex.backtrace
							errors=errors+1
							begin
								customMetadata.putText("Language-error-status",-2)
								customMetadata.putText("Language-error-message",ex.message)
								customMetadata.putText("Language-error-details",ex.backtrace)
							rescue Exception => ex
								puts ex
								puts ex.backtrace
							end
						end
					end
					dialog.setImportCurrent(translated + errors)
					dialog.setImportMessage("Imported:#{translated} items, #{errors} errors")
				end
				puts "finished importing items"
			end
			threads.each(&:join)
			puts "Finished translating #{total} items with #{errors} errors"
			$window.openTab("workbench",{"search"=>'custom-metadata:"Language-Id":*'})
			if(errors > 0)
				$window.openTab("workbench",{"search"=>'custom-metadata:"Language-error-message":*'})
			end
		end
	end
	
end
