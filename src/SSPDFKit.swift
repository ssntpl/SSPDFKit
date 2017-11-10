//
//  SSPDFKit.swift
//
//  Created by Sword Software on 28/07/17.
//  Copyright © 2017 Sword Software. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

@objc protocol SSPDFKitDelegate {
    func pdfSaved(message: String)
    //    func error(error: String)
}

class SSPDFKit: NSObject {
    
    private var sourcePDFUrl:URL!
    private var textToSearch:String!
    private var destinatinationPDFUrl:URL!
    private var document:CGPDFDocument!
    
    private var currentScannedPageNumber = 0
    private var textFoundOnPageNumber = 0
    private var textFound = false
    private var isPDFSplittedAndSaved = false
    
    var delegate:SSPDFKitDelegate?
    
    override init() {
        
    }
    
    /**
     split pdf file after searching of given text.
     - Parameter sourcePDFUrl: source pdf file path url.
     - Parameter textToSearch: text to search in source pdf file.
     - Parameter destinatinationPDFUrl: destination pdf file path url.
     */
    func startSplitting(sourcePDFUrl:URL, textToSearch:String, destinatinationPDFUrl:URL,completionBlock:(_ success:Bool) -> Void){
        
        //self.sourcePDFUrl = sourcePDFUrl
        self.textToSearch = textToSearch
        self.destinatinationPDFUrl = destinatinationPDFUrl
        
        self.document = CGPDFDocument(sourcePDFUrl as CFURL)
        if self.document == nil {
            delegate?.pdfSaved(message: "Wrong source url")
            completionBlock(false)
            return
        }
        let noOfPages :Int = document!.numberOfPages
        let operatorTable = newOperatorTable()
        var contentStream:CGPDFContentStreamRef!
        var scanner:CGPDFScannerRef!
        for k in 1...noOfPages {
            contentStream = CGPDFContentStreamCreateWithPage((document?.page(at: k))!);
            var selfObj = self
            currentScannedPageNumber = k
            scanner = CGPDFScannerCreate(contentStream, operatorTable, &selfObj);
            _ = CGPDFScannerScan(scanner);
            CGPDFScannerRelease(scanner);
            CGPDFContentStreamRelease(contentStream);
            if textFound && isPDFSplittedAndSaved{
                completionBlock(true)
                return
            }
            if !textFound && k == noOfPages {
                completionBlock(false)
                delegate?.pdfSaved(message: "text not found")
                return
            }
        }
        if textFound && isPDFSplittedAndSaved {
            completionBlock(true)
        } else {
            completionBlock(false)
        }
        
    }
    
    private func newOperatorTable() -> CGPDFOperatorTableRef {
        let operatorTable = CGPDFOperatorTableCreate()
        
        CGPDFOperatorTableSetCallback(operatorTable!, "\'", { scannerRef, b in
            //print("\'")
            var pdfString: CGPDFStringRef?
            if CGPDFScannerPopString(scannerRef, &pdfString) {
                let str = CGPDFStringCopyTextString(pdfString!) as! String
                if let info = b?.load(as: SSPDFKit.self) {
                    if str.contains(info.textToSearch) && !info.textFound {
                        info.textFound = true
                        //print("YES, I got text")
                        //print(str)
                        info.textFoundOnPageNumber = info.currentScannedPageNumber
                        //print(info.currentScannedPageNumber)
                        info.generatePDF()
                    }
                }
            }
        })
        
        
        CGPDFOperatorTableSetCallback(operatorTable!, "\"", { scannerRef, b in
            //print("\"")
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "TJ", { scannerRef, b in
            //print("TJ")
            
        })
        
        CGPDFOperatorTableSetCallback(operatorTable!, "Tj", { scannerRef, b in
            //print("Tj")
            var pdfString: CGPDFStringRef?
            if CGPDFScannerPopString(scannerRef, &pdfString) {
                let str = CGPDFStringCopyTextString(pdfString!) as! String
                if let info = b?.load(as: SSPDFKit.self) {
                    if str.contains(info.textToSearch) && !info.textFound {
                        info.textFound = true
                        //print("YES, I got this text")
                        //print(str)
                        info.textFoundOnPageNumber = info.currentScannedPageNumber
                        //print(info.currentScannedPageNumber)
                        info.generatePDF()
                    }
                }
            }
        })
        
        CGPDFOperatorTableSetCallback(operatorTable!, "Tm", { scannerRef, b in
            //print("Tm")
            
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "Td", { scannerRef, b in
            //print("Td")
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "TD", { scannerRef, b in
            //print("TD")
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "T*", { scannerRef, b in
            //print("T*")
            
        })
        
        CGPDFOperatorTableSetCallback(operatorTable!, "Tw", { scannerRef, b in
            //print("Tw")
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "Tc", { scannerRef, b in
            //print("Tc")
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "TL", { scannerRef, b in
            //print("TL")
            
            var pdfString: CGPDFStringRef?
            if CGPDFScannerPopString(scannerRef, &pdfString) {
                
                let str = CGPDFStringCopyTextString(pdfString!) as! String
                //print(str)
                
            }
            
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "Tz", { scannerRef, b in
            //print("Tz")
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "Ts", { scannerRef, b in
            //print("Ts")
        })
        CGPDFOperatorTableSetCallback(operatorTable!, "Tf", { scannerRef, b in
            //print("Tf")
        })
       
        
        return operatorTable!
    }
    
    
    private func generatePDF() {
        
        //print(destinatinationPDFUrl)
        if let context = CGContext(destinatinationPDFUrl as CFURL, mediaBox: nil, nil) {
            let pdfDoc : CGPDFDocument  = document
            //let pdfPage : CGPDFPage = pdfDoc.page(at: textFoundOnPageNumber)!
            //        var pdfCropBoxRect : CGRect = pdfPage.getBoxRect(.mediaBox)
            
            for i in textFoundOnPageNumber...pdfDoc.numberOfPages {
                
                let pdfPage2 : CGPDFPage = pdfDoc.page(at: i)!
                var pdfCropBoxRect : CGRect = pdfPage2.getBoxRect(.mediaBox)
                context.beginPage(mediaBox: &pdfCropBoxRect);
                
                context.drawPDFPage(pdfPage2);
                context.endPage();
            }
            context.closePDF()
            isPDFSplittedAndSaved = true
            delegate?.pdfSaved(message: "pdf saved at \(destinatinationPDFUrl!)")
        } else {
            delegate?.pdfSaved(message: "Wrong destination path")
            return
        }
        
    }
    
    /**
     delete pages from pdf file by given page numbers and save it to destination pdf file path url.
     - Parameter sourcePDFUrl: source pdf file path url.
     - Parameter destinatinationPDFUrl: destination pdf file path url.
     - Parameter pdfPages: array of page numbers.
     */
    func deletePages(sourcePDFUrl:URL, destinatinationPDFUrl:URL, pdfPages:[Int]) {
        self.document = CGPDFDocument(sourcePDFUrl as CFURL)
        if self.document == nil {
            delegate?.pdfSaved(message: "Wrong source url")
            return
        }
        //print(destinatinationPDFUrl)
        if let context = CGContext(destinatinationPDFUrl as CFURL, mediaBox: nil, nil) {
            let pdfDoc : CGPDFDocument  = document
            //let pdfPage : CGPDFPage = pdfDoc.page(at: textFoundOnPageNumber)!
            //        var pdfCropBoxRect : CGRect = pdfPage.getBoxRect(.mediaBox)
            
            var array1:[Int] = []
            for i in 1...document.numberOfPages {
                array1.append(i)
            }
            
            let array2 = Array(Set(array1).subtracting(pdfPages)).sorted()
            
            
            for i in array2 {
                let pdfPage2 : CGPDFPage = pdfDoc.page(at: i)!
                var pdfCropBoxRect : CGRect = pdfPage2.getBoxRect(.mediaBox)
                context.beginPage(mediaBox: &pdfCropBoxRect);
                
                context.drawPDFPage(pdfPage2);
                context.endPage();
            }
            context.closePDF()
            delegate?.pdfSaved(message: "pdf saved at \(destinatinationPDFUrl)")
        } else {
            delegate?.pdfSaved(message: "Wrong destination path")
            return
        }
    }
    
    
    /**
     merge multiple pdf files.
     - Parameter pdfPaths: array of source pdf file path urls.
     - Parameter destinatinationPDFUrl: destination pdf file path url.
     */
    func mergePdf(pdfPaths:[URL], destinatinationPDFUrl:URL){
//        self.document = CGPDFDocument(sourcePDFUrl as CFURL)
//        if self.document == nil {
//            delegate?.pdfSaved(message: "Wrong source url")
//            return
//        }
        //print(destinatinationPDFUrl)
        if let context = CGContext(destinatinationPDFUrl as CFURL, mediaBox: nil, nil) {
            
            for url in pdfPaths{
                if let document = CGPDFDocument(url as CFURL) {
                    
                    for i in 1...document.numberOfPages {
                        
                        let pdfPage2 : CGPDFPage = document.page(at: i)!
                        var pdfCropBoxRect : CGRect = pdfPage2.getBoxRect(.mediaBox)
                        context.beginPage(mediaBox: &pdfCropBoxRect);
                        
                        context.drawPDFPage(pdfPage2);
                        context.endPage();
                    }
                } else {
                    delegate?.pdfSaved(message: "some file path urls are incorrect")
                }
            }
            context.closePDF()
            delegate?.pdfSaved(message: "pdf saved at \(destinatinationPDFUrl)")
        } else {
            delegate?.pdfSaved(message: "Wrong destination path")
            return
        }
        
    }
    
    
    /**
     save only pages according to given page numbers to destination pdf file path url.
     - Parameter sourcePDFUrl: source pdf file path url.
     - Parameter destinatinationPDFUrl: destination pdf file path url.
     - Parameter pdfPages: array of page numbers.
     */
    func getOnlyThesePages(sourcePDFUrl:URL, destinatinationPDFUrl:URL, pdfPages:[Int]) {
        self.document = CGPDFDocument(sourcePDFUrl as CFURL)
        if self.document == nil {
            delegate?.pdfSaved(message: "Wrong source url")
            return
        }
        //print(destinatinationPDFUrl)
        if let context = CGContext(destinatinationPDFUrl as CFURL, mediaBox: nil, nil) {
            let pdfDoc : CGPDFDocument  = document
            
            for i in pdfPages {
                if let pdfPage2 : CGPDFPage = pdfDoc.page(at: i) {
                    var pdfCropBoxRect : CGRect = pdfPage2.getBoxRect(.mediaBox)
                    context.beginPage(mediaBox: &pdfCropBoxRect);
                    
                    context.drawPDFPage(pdfPage2);
                    context.endPage();
                } else {
                    delegate?.pdfSaved(message: "page \(i) not exists")
                }
            }
            context.closePDF()
            delegate?.pdfSaved(message: "pdf saved at \(destinatinationPDFUrl)")
        } else {
            delegate?.pdfSaved(message: "Wrong destination path")
            return
        }
    }
    
    
    
    /**
     create a new pdf file.
     - Parameter text: text to add in pdf file.
     - Parameter destinatinationPDFUrl: destination pdf file path url.
    */
    func createPdf(text: String, destinatinationPDFUrl:URL) {
        // 1. Create Print Formatter with input text.
        
        let formatter = UIMarkupTextPrintFormatter(markupText: text)
        
        // 2. Add formatter with pageRender
        
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(formatter, startingAtPageAt: 0)
        
        
        // 3. Assign paperRect and //printableRect
        
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        let printable = page.insetBy(dx: 0, dy: 0)
        
        render.setValue(NSValue(cgRect: page), forKey: "paperRect")
        render.setValue(NSValue(cgRect: printable), forKey: "printableRect")
        
        
        // 4. Create PDF context and draw
        let rect = CGRect.zero
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, rect, nil)
        
        
        for i in 1...render.numberOfPages {
            
            UIGraphicsBeginPDFPage();
            let bounds = UIGraphicsGetPDFContextBounds()
            render.drawPage(at: i - 1, in: bounds)
        }
        
        UIGraphicsEndPDFContext();
        
        
        // 5. Save PDF file
        
       
        
        
        if pdfData.write(to: destinatinationPDFUrl, atomically: true) {
            delegate?.pdfSaved(message: "pdf saved")
        } else {
            delegate?.pdfSaved(message: "Wrong destination path")
        }

    }

    
}
