function daysInAdvanceDiscountLevel(ticketDate) {
  today = new Date()
  msPerDay = 24 * 60 * 60 * 1000
  DIA = (ticketDate.getTime() - today.getTime()) / msPerDay + 1
  DIA = Math.floor(DIA)

  return DIA 
}

function setDIA(theForm) {
// use split to get from user date format to JS date format
// dateData= split("/", theForm.departDate)
// new Date(dateData[2], dateData[1], dateData[0])
  	dateString = theForm.departDate.value
  	dateArray = dateString.split("/")
  	userDate = new Date(parseInt(dateArray[2], 10), 
                     parseInt(dateArray[0],10)-1, 
                      parseInt(dateArray[1],10))
  	theForm.advanceDiscount.value = daysInAdvanceDiscountLevel(userDate)
  	return true
}
